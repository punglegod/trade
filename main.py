"""
甲醇期货交易信号辅助系统
基于均线回踩策略，提供买卖信号及完整决策依据
"""

import backtrader as bt
import akshare as ak
import pandas as pd
import logging
import csv
import os
from datetime import datetime

# ============================================================
# 1. 全局配置
# ============================================================
CONFIG = {
    'symbol': 'MA',                # 品种代码
    'start_date': '20240101',      # 回测起始日期
    'end_date': '20251231',        # 回测结束日期
    'initial_cash': 10000.0,       # 初始资金
    'commission': 3.0,             # 手续费（元/手）
    'margin': 4000.0,              # 保证金
    'mult': 10.0,                  # 合约乘数（1手=10吨）
    'slippage': 1.0,               # 滑点（元）
    'jump_filter_pct': 6.0,        # 连续合约异常跳空过滤阈值(%)
    'risk_per_trade': 0.0,         # 单笔风险占比(0=关闭风险仓位)
    'trail_atr_multiplier': 3.0,   # 移动止盈 ATR 倍数
}

# ============================================================
# 2. 日志初始化（延迟初始化，模块级只做基本配置）
# ============================================================
logger = logging.getLogger('TradeSignal')


def setup_logging(enable_file=True):
    """初始化日志系统，同时输出到控制台和（可选）文件"""
    logger.setLevel(logging.DEBUG)
    # 避免重复添加 handler
    if logger.handlers:
        return logger
    # 控制台 handler
    ch = logging.StreamHandler()
    ch.setLevel(logging.INFO)
    ch.setFormatter(logging.Formatter('%(message)s'))
    logger.addHandler(ch)
    # 文件 handler（可选）
    if enable_file:
        os.makedirs('results', exist_ok=True)
        fh = logging.FileHandler('results/backtest.log', encoding='utf-8')
        fh.setLevel(logging.DEBUG)
        fh.setFormatter(logging.Formatter('%(asctime)s %(levelname)s %(message)s'))
        logger.addHandler(fh)
    return logger

# ============================================================
# 3. 策略类
# ============================================================
class MA_Procurement_Strategy(bt.Strategy):
    """均线回踩买入策略 —— 附带完整信号依据与风控"""
    params = (
        ('ma_period', 20),             # 20日均线周期
        ('stop_loss', 0.03),           # 固定止损比例 3%
        ('atr_period', 14),            # ATR 周期
        ('atr_stop_multiplier', 2.0),  # ATR 止损倍数
        ('vol_period', 20),            # 成交量均值周期
        ('risk_per_trade', 0.0),       # 风险仓位占比(0=固定1手)
        ('trail_atr_multiplier', 3.0), # 移动止盈 ATR 倍数
        ('adx_threshold', 25),         # ADX趋势强度阈值
        ('partial_take_profit', True), # 是否启用分批止盈
        ('tp_level1_pct', 0.03),       # 第一止盈位 3%
        ('tp_level2_pct', 0.06),       # 第二止盈位 6%
        ('partial_exit_ratio', 0.5),   # 分批止盈比例 50%
    )

    def __init__(self):
        # 基础数据引用
        self.dataclose = self.datas[0].close
        self.datalow = self.datas[0].low
        self.datahigh = self.datas[0].high
        self.dataopen = self.datas[0].open
        self.datavolume = self.datas[0].volume

        # 技术指标
        self.ma = bt.indicators.SimpleMovingAverage(
            self.dataclose, period=self.params.ma_period)
        self.atr = bt.indicators.AverageTrueRange(
            self.datas[0], period=self.params.atr_period)
        self.vol_ma = bt.indicators.SimpleMovingAverage(
            self.datavolume, period=self.params.vol_period)

        # 趋势强度指标
        self.adx = bt.indicators.AverageDirectionalMovementIndex(
            self.datas[0], period=14)
        self.plus_di = bt.indicators.PlusDirectionalIndicator(
            self.datas[0], period=14)
        self.minus_di = bt.indicators.MinusDirectionalIndicator(
            self.datas[0], period=14)

        # 布林带用于波动率和超买超卖判断
        self.bollinger = bt.indicators.BollingerBands(
            self.dataclose, period=20, devfactor=2.0)

        # MACD 用于趋势确认
        self.macd = bt.indicators.MACD(self.dataclose)
        self.macd_cross = bt.indicators.CrossOver(self.macd.macd, self.macd.signal)

        # 订单跟踪
        self.order = None

        # 信号记录列表（用于导出CSV）
        self.signal_records = []

        # 交易历史（由 notify_trade 维护）
        self.trade_history = []

        # 资金曲线记录
        self.equity_curve = {}  # {date: portfolio_value}

        # 持仓风控状态
        self.highest_since_entry = None
        self.entry_price = None
        self.position_size = 0          # 当前持仓手数
        self.partial_exit_done = False  # 是否已执行分批止盈

    def _calc_order_size(self, cur_price, stop_price):
        """按风险预算计算手数；risk_per_trade<=0 时退回固定 1 手"""
        risk_per_trade = float(self.params.risk_per_trade or 0)
        if risk_per_trade <= 0:
            return 1

        stop_distance = cur_price - stop_price
        if stop_distance <= 0:
            return 1

        account_value = float(self.broker.getvalue())
        risk_cash = account_value * risk_per_trade
        per_lot_risk = stop_distance * CONFIG['mult']
        if per_lot_risk <= 0:
            return 1

        size_by_risk = int(risk_cash // per_lot_risk)
        if size_by_risk < 1:
            self.log('【仓位提示】风险预算不足 1 手，按最小 1 手执行。')
            size_by_risk = 1

        # 保证金约束
        available_cash = float(self.broker.getcash())
        size_by_margin = int(available_cash // CONFIG['margin']) if CONFIG['margin'] > 0 else size_by_risk
        final_size = max(1, min(size_by_risk, size_by_margin if size_by_margin > 0 else 1))
        return final_size

    def _get_market_regime(self):
        """判断市场环境: trending/ranging/volatile"""
        try:
            adx_val = self.adx[0] if self.adx else 0
            bb_width = ((self.bollinger.lines.top[0] - self.bollinger.lines.bot[0]) /
                       self.bollinger.lines.mid[0] * 100) if self.bollinger.lines.mid[0] else 0

            if adx_val > self.params.adx_threshold:
                return 'trending', adx_val, bb_width
            elif bb_width > 5.0:
                return 'volatile', adx_val, bb_width
            else:
                return 'ranging', adx_val, bb_width
        except:
            return 'unknown', 0, 0

    def _check_trend_alignment(self):
        """检查多指标趋势一致性"""
        try:
            # MA排列
            ma_aligned = self.dataclose[0] > self.ma[0]
            # MACD金叉后
            macd_aligned = self.macd.macd[0] > self.macd.signal[0] if self.macd else False
            # DI+ > DI- (多头趋势)
            di_aligned = self.plus_di[0] > self.minus_di[0] if self.plus_di and self.minus_di else False

            score = sum([ma_aligned, macd_aligned, di_aligned])
            return score, ma_aligned, macd_aligned, di_aligned
        except:
            return 0, False, False, False

    def log(self, txt, dt=None):
        """通过 logging 输出日志"""
        dt = dt or self.datas[0].datetime.date(0)
        logger.info(f'{dt.isoformat()}, {txt}')

    # ----------------------------------------------------------
    # 订单状态回调 —— 修复信号丢失 bug
    # ----------------------------------------------------------
    def notify_order(self, order):
        if order.status in [order.Completed]:
            if order.isbuy():
                self.highest_since_entry = float(order.executed.price)
                self.entry_price = float(order.executed.price)
                self.log(
                    f'【订单成交-买入】价格: {order.executed.price:.2f}, '
                    f'数量: {order.executed.size}, '
                    f'手续费: {order.executed.comm:.2f}')
            else:
                self.highest_since_entry = None
                self.entry_price = None
                self.log(
                    f'【订单成交-卖出】价格: {order.executed.price:.2f}, '
                    f'数量: {order.executed.size}, '
                    f'手续费: {order.executed.comm:.2f}')
        elif order.status in [order.Canceled, order.Margin, order.Rejected]:
            self.log(f'【订单异常】状态: {order.getstatusname()}')
        # 无论成交、取消还是拒绝，都重置 order 引用
        if order.status in [order.Completed, order.Canceled, order.Margin, order.Rejected]:
            self.order = None

    def notify_trade(self, trade):
        """交易关闭时记录盈亏"""
        if trade.isclosed:
            # 使用持仓成本计算收益率更准确
            entry_cost = self.entry_price if self.entry_price else trade.price
            denom = entry_cost * abs(trade.size) * CONFIG['mult']
            pnl_pct = (trade.pnlcomm / denom * 100) if denom else 0
            self.log(
                f'【交易结束】毛利: {trade.pnl:.2f}, '
                f'净利(扣费): {trade.pnlcomm:.2f}, '
                f'收益率: {pnl_pct:.2f}%')
            self.trade_history.append({
                'close_date': self.datas[0].datetime.date(0).isoformat(),
                'pnl': trade.pnl,
                'pnl_comm': trade.pnlcomm,
                'pnl_pct': pnl_pct,
            })
            # 把盈亏回填到最近一条卖出信号记录
            if self.signal_records:
                for rec in reversed(self.signal_records):
                    if rec['type'] == '卖出' and rec.get('pnl', '') == '':
                        rec['pnl'] = f'{trade.pnlcomm:.2f}'
                        rec['pnl_pct'] = f'{pnl_pct:.2f}%'
                        break

    # ----------------------------------------------------------
    # 核心策略逻辑
    # ----------------------------------------------------------
    def prenext(self):
        """在指标未就绪时记录初始资金"""
        dt = self.datas[0].datetime.date(0)
        self.equity_curve[dt] = self.broker.getvalue()

    def next(self):
        # 记录资金曲线（包含所有天数）
        dt = self.datas[0].datetime.date(0)
        self.equity_curve[dt] = self.broker.getvalue()

        if self.order:
            return

        cur_price = self.dataclose[0]
        cur_low = self.datalow[0]
        cur_high = self.datahigh[0]
        ma_val = self.ma[0]
        atr_val = self.atr[0]
        cur_vol = self.datavolume[0]
        avg_vol = self.vol_ma[0]
        dt_str = dt.isoformat()

        # 价格与均线偏离度
        deviation = (cur_price - ma_val) / ma_val * 100 if ma_val else 0

        if not self.position:
            # ====== 买入逻辑 ======
            # 获取市场环境和趋势一致性
            regime, adx_val, bb_width = self._get_market_regime()
            trend_score, ma_ok, macd_ok, di_ok = self._check_trend_alignment()

            # 核心买入条件:
            # 1. 收盘在均线上方 + 最低价触及均线 (回踩确认)
            # 2. 偏离度在合理范围 (<5%，避免追高)
            # 3. 趋势评分 >= 2 (至少两个指标共振)
            # 4. 避免高波动环境 (ADX过高且布林带过宽)

            pullback_ok = cur_price > ma_val and cur_low <= ma_val
            deviation_ok = deviation <= 5.0
            trend_ok = trend_score >= 2
            regime_ok = regime != 'volatile' or adx_val < 40

            if pullback_ok and deviation_ok and trend_ok and regime_ok:
                # 成交量确认: 要求量能不低于均量的70%（避免无量假突破）
                vol_ratio = cur_vol / avg_vol if avg_vol else 1
                if vol_ratio < 0.7:  # 量能过滤
                    return

                vol_status = '缩量' if vol_ratio < 0.8 else ('放量' if vol_ratio > 1.2 else '正常')

                # 根据市场环境调整仓位
                size_multiplier = 1.0
                if regime == 'trending' and trend_score == 3:
                    size_multiplier = 1.2  # 强趋势加仓
                elif regime == 'ranging':
                    size_multiplier = 0.8  # 震荡减仓

                # ATR 建议止损位
                atr_stop = cur_price - self.params.atr_stop_multiplier * atr_val
                # 建议操作价位（当前收盘价附近）
                suggest_price = cur_price

                trend_info = f"趋势评分:{trend_score}/3 (MA:{ma_ok}, MACD:{macd_ok}, DI:{di_ok})"
                regime_info = f"市场环境:{regime} (ADX:{adx_val:.1f})"

                signal_text = (
                    f'\n{"="*50}\n'
                    f'  ★ 买入信号 - 智能回踩进场\n'
                    f'{"="*50}\n'
                    f'  当前价格:     {cur_price:.2f}\n'
                    f'  MA{self.params.ma_period}均线:   {ma_val:.2f}\n'
                    f'  偏离度:       {deviation:+.2f}%\n'
                    f'  当日最低价:   {cur_low:.2f} (触及均线 {ma_val:.2f})\n'
                    f'  ATR({self.params.atr_period}):    {atr_val:.2f}\n'
                    f'  {trend_info}\n'
                    f'  {regime_info}\n'
                    f'  当日成交量:   {cur_vol:.0f}  均量: {avg_vol:.0f}  '
                    f'量比: {vol_ratio:.2f} ({vol_status})\n'
                    f'  ------------------------------------------------\n'
                    f'  建议操作价位: {suggest_price:.2f}\n'
                    f'  建议止损位:   {atr_stop:.2f} '
                    f'(价格 - {self.params.atr_stop_multiplier}×ATR)\n'
                    f'{"="*50}'
                )
                self.log(signal_text)

                fixed_stop_price = cur_price * (1 - self.params.stop_loss)
                initial_stop_price = min(atr_stop, fixed_stop_price)
                order_size = self._calc_order_size(cur_price=cur_price, stop_price=initial_stop_price)
                order_size = int(order_size * size_multiplier)
                order_size = max(1, order_size)

                self.order = self.buy(size=order_size)
                self.position_size = order_size
                self.partial_exit_done = False

                # 记录信号
                self.signal_records.append({
                    'date': dt_str,
                    'type': '买入',
                    'price': f'{cur_price:.2f}',
                    'ma': f'{ma_val:.2f}',
                    'deviation': f'{deviation:+.2f}%',
                    'atr': f'{atr_val:.2f}',
                    'volume_status': vol_status,
                    'suggest_stop': f'{atr_stop:.2f}',
                    'reason': f'智能回踩进场 | {trend_info} | {regime_info}',
                    'pnl': '',
                })
        else:
            # ====== 卖出逻辑 ======
            # 使用实际入场价格，如果没有则使用 position.price
            cost = self.entry_price if self.entry_price else self.position.price
            price_change = (cur_price - cost) / cost if cost else 0
            pnl_pct = price_change * 100

            # ATR 动态止损阈值
            atr_stop_price = cost - self.params.atr_stop_multiplier * atr_val
            # 固定比例止损阈值
            fixed_stop_price = cost * (1 - self.params.stop_loss)

            # 移动止盈止损位（随最高价抬升）
            if self.highest_since_entry is None:
                self.highest_since_entry = cost
            self.highest_since_entry = max(float(cur_high), self.highest_since_entry)
            trail_stop_price = self.highest_since_entry - self.params.trail_atr_multiplier * atr_val

            # 分批止盈检查
            partial_exit_triggered = False
            if (self.params.partial_take_profit and not self.partial_exit_done and
                self.position_size > 1):
                # 第一止盈位
                if pnl_pct >= self.params.tp_level1_pct * 100:
                    exit_size = max(1, int(self.position_size * self.params.partial_exit_ratio))
                    self.log(f'【分批止盈】盈利{pnl_pct:.2f}%，卖出{exit_size}/{self.position_size}手')
                    self.order = self.sell(size=exit_size)
                    self.partial_exit_done = True
                    self.position_size -= exit_size

                    # 记录分批止盈信号
                    self.signal_records.append({
                        'date': dt_str,
                        'type': '卖出(部分)',
                        'price': f'{cur_price:.2f}',
                        'ma': f'{ma_val:.2f}',
                        'deviation': f'{deviation:+.2f}%',
                        'atr': f'{atr_val:.2f}',
                        'volume_status': '',
                        'suggest_stop': '',
                        'reason': f'分批止盈1 (盈利{pnl_pct:.2f}%)',
                        'pnl': '',
                    })
                    return

            # 动态确定有效止损位：盈利后启用移动止盈
            if cur_price > cost:
                # 有盈利时，取最严格的止损位（保护利润）
                effective_stop = max(min(atr_stop_price, fixed_stop_price), trail_stop_price)
            else:
                # 亏损时，使用初始止损
                effective_stop = min(atr_stop_price, fixed_stop_price)

            sell_reason = None
            if cur_price <= effective_stop:
                if cur_price <= trail_stop_price and cur_price > cost:
                    sell_reason = (
                        f'触发ATR移动止盈 (最高价{self.highest_since_entry:.2f}, '
                        f'止损位: {trail_stop_price:.2f})'
                    )
                elif cur_price <= atr_stop_price and cur_price <= fixed_stop_price:
                    sell_reason = f'触发双重止损 (ATR止损{atr_stop_price:.2f} & 固定止损{fixed_stop_price:.2f})'
                elif cur_price <= atr_stop_price:
                    sell_reason = f'触发ATR动态止损 (止损位: {atr_stop_price:.2f})'
                else:
                    sell_reason = f'触发固定{self.params.stop_loss*100:.0f}%止损 (止损位: {fixed_stop_price:.2f})'
            elif cur_price < ma_val and pnl_pct > 0:
                # 优化：只在盈利时因跌破均线离场，避免亏损时过早离场
                sell_reason = f'跌破MA{self.params.ma_period}均线离场 (盈利保护)'

            if sell_reason:
                signal_text = (
                    f'\n{"="*50}\n'
                    f'  ✖ 卖出信号 - {sell_reason}\n'
                    f'{"="*50}\n'
                    f'  当前价格:     {cur_price:.2f}\n'
                    f'  持仓成本:     {cost:.2f}\n'
                    f'  当前盈亏:     {pnl_pct:+.2f}%\n'
                    f'  MA{self.params.ma_period}均线:   {ma_val:.2f}\n'
                    f'  偏离度:       {deviation:+.2f}%\n'
                    f'  ATR({self.params.atr_period}):    {atr_val:.2f}\n'
                    f'  ATR止损位:    {atr_stop_price:.2f}\n'
                    f'  固定止损位:   {fixed_stop_price:.2f}\n'
                    f'  移动止盈位:   {trail_stop_price:.2f}\n'
                    f'{"="*50}'
                )
                self.log(signal_text)
                self.order = self.close()
                self.position_size = 0
                self.partial_exit_done = False

                # 记录信号
                self.signal_records.append({
                    'date': dt_str,
                    'type': '卖出',
                    'price': f'{cur_price:.2f}',
                    'ma': f'{ma_val:.2f}',
                    'deviation': f'{deviation:+.2f}%',
                    'atr': f'{atr_val:.2f}',
                    'volume_status': '',
                    'suggest_stop': '',
                    'reason': sell_reason,
                    'pnl': '',  # 由 notify_trade 回填
                })

    def stop(self):
        """策略结束时导出信号记录为 CSV"""
        if not self.signal_records:
            logger.info('本次回测未产生任何信号。')
            return
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        csv_path = f'results/signals_{timestamp}.csv'
        fieldnames = [
            'date', 'type', 'price', 'ma', 'deviation',
            'atr', 'volume_status', 'suggest_stop', 'reason', 'pnl'
        ]
        try:
            with open(csv_path, 'w', newline='', encoding='utf-8-sig') as f:
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(self.signal_records)
            logger.info(f'信号记录已导出: {csv_path} (共 {len(self.signal_records)} 条)')
        except Exception as e:
            logger.error(f'导出信号记录失败: {e}')


# ============================================================
# 4. 数据获取（含异常处理与校验）
# ============================================================
def _adjust_rollover_jumps(df: pd.DataFrame, jump_filter_pct: float):
    """对连续合约异常跳空做前向平滑，降低换月跳点对指标的扭曲"""
    if jump_filter_pct is None or jump_filter_pct <= 0 or df.empty:
        return df, 0

    adjusted = df.copy()
    ohlc_cols = ['open', 'high', 'low', 'close']
    cum_factor = 1.0
    jump_count = 0

    for i in range(len(df)):
        raw_row = df.iloc[i]
        if i > 0:
            prev_close = float(adjusted.iloc[i - 1]['close'])
            cur_open = float(raw_row['open']) * cum_factor
            if prev_close != 0:
                gap_pct = (cur_open - prev_close) / prev_close * 100
                if abs(gap_pct) >= jump_filter_pct:
                    # 把当前开盘平滑到上一根收盘，后续价格同因子平移
                    factor = prev_close / cur_open if cur_open else 1.0
                    cum_factor *= factor
                    jump_count += 1

        for col in ohlc_cols:
            adjusted.iat[i, adjusted.columns.get_loc(col)] = float(raw_row[col]) * cum_factor

    return adjusted, jump_count


def get_ma_data(symbol=None, start_date=None, end_date=None, jump_filter_pct=None):
    """获取甲醇主力合约日线数据，包含完整异常处理与数据校验"""
    sym = symbol or CONFIG['symbol']
    sd = start_date or CONFIG['start_date']
    ed = end_date or CONFIG['end_date']
    jump_filter = CONFIG['jump_filter_pct'] if jump_filter_pct is None else jump_filter_pct

    logger.info(f'正在获取 {sym} 期货数据 ({sd} ~ {ed}) ...')

    df = None
    fetch_errors = []

    # 兼容不同版本 AkShare:
    # 1) 新版通常提供 futures_main_historical_df
    # 2) 旧版可回退到 futures_main_sina (symbol 需类似 MA0)
    if hasattr(ak, 'futures_main_historical_df'):
        try:
            df = ak.futures_main_historical_df(
                symbol=sym, start_date=sd, end_date=ed)
            logger.info('数据源: ak.futures_main_historical_df')
        except Exception as e:
            fetch_errors.append(f'futures_main_historical_df: {e}')

    if (df is None or df.empty) and hasattr(ak, 'futures_main_sina'):
        sina_symbol = sym if str(sym).endswith('0') else f'{sym}0'
        try:
            df = ak.futures_main_sina(
                symbol=sina_symbol, start_date=sd, end_date=ed)
            if df is not None and not df.empty:
                df = df.rename(columns={
                    '日期': 'date',
                    '开盘价': 'open',
                    '最高价': 'high',
                    '最低价': 'low',
                    '收盘价': 'close',
                    '成交量': 'volume',
                })
            logger.info(f'数据源: ak.futures_main_sina ({sina_symbol})')
        except Exception as e:
            fetch_errors.append(f'futures_main_sina: {e}')

    # 校验 DataFrame 是否为空
    if df is None or df.empty:
        detail = '; '.join(fetch_errors) if fetch_errors else '未命中可用数据接口'
        raise RuntimeError(f'获取到的数据为空，请检查品种代码和日期范围。详情: {detail}')

    # 校验必要列是否存在
    required_cols = ['date', 'open', 'high', 'low', 'close', 'volume']
    missing = [c for c in required_cols if c not in df.columns]
    if missing:
        raise RuntimeError(f'数据缺少必要列: {missing}，实际列: {list(df.columns)}')

    # 日期转换与索引
    df['date'] = pd.to_datetime(df['date'], errors='coerce')
    df.dropna(subset=['date'], inplace=True)
    df.set_index('date', inplace=True)

    # 选取需要的列
    df = df[['open', 'high', 'low', 'close', 'volume']].copy()

    # 数值化，兼容字符串数字
    for col in ['open', 'high', 'low', 'close', 'volume']:
        df[col] = pd.to_numeric(df[col], errors='coerce')
    df[['open', 'high', 'low', 'close']] = df[['open', 'high', 'low', 'close']].astype(float)
    df.dropna(subset=['open', 'high', 'low', 'close', 'volume'], inplace=True)

    # NaN 检查与清洗
    nan_count = df.isna().sum().sum()
    if nan_count > 0:
        logger.warning(f'数据中存在 {nan_count} 个 NaN 值，已执行前向填充清洗。')
        df.ffill(inplace=True)
        df.dropna(inplace=True)  # 如果头部仍有 NaN 则删除

    if df.empty:
        raise RuntimeError('清洗后数据为空，请调整品种代码或时间范围。')

    # 连续合约异常跳空平滑（用于降低换月拼接噪声）
    df, jump_count = _adjust_rollover_jumps(df, float(jump_filter))
    if jump_count > 0:
        logger.warning(f'检测并平滑 {jump_count} 处异常跳空（阈值 {jump_filter:.2f}%）。')

    logger.info(
        f'数据加载完成: {len(df)} 条记录, '
        f'时间范围 {df.index[0].strftime("%Y-%m-%d")} ~ '
        f'{df.index[-1].strftime("%Y-%m-%d")}')
    return df


# ============================================================
# 5. 绩效分析
# ============================================================
def get_performance_metrics(results) -> dict:
    """解析回测结果，返回绩效指标字典"""
    strat = results[0]
    metrics = {}

    # 交易分析
    try:
        ta = strat.analyzers.trade_analyzer.get_analysis()
        metrics['total_trades'] = ta.get('total', {}).get('total', 0)
        metrics['won'] = ta.get('won', {}).get('total', 0)
        metrics['lost'] = ta.get('lost', {}).get('total', 0)
        total = metrics['total_trades']
        metrics['win_rate'] = (metrics['won'] / total * 100) if total > 0 else 0
        avg_win = ta.get('won', {}).get('pnl', {}).get('average', 0)
        avg_loss = abs(ta.get('lost', {}).get('pnl', {}).get('average', 1))
        metrics['profit_ratio'] = (avg_win / avg_loss) if avg_loss else 0
    except Exception:
        metrics.update({'total_trades': 0, 'won': 0, 'lost': 0, 'win_rate': 0, 'profit_ratio': 0})

    # 最大回撤
    try:
        dd = strat.analyzers.drawdown.get_analysis()
        metrics['max_drawdown'] = dd.get('max', {}).get('drawdown', 0)
    except Exception:
        metrics['max_drawdown'] = 0

    # 夏普率
    try:
        sr = strat.analyzers.sharpe_ratio.get_analysis()
        metrics['sharpe_ratio'] = sr.get('sharperatio', None)
    except Exception:
        metrics['sharpe_ratio'] = None

    # 总收益率
    try:
        ret = strat.analyzers.returns.get_analysis()
        metrics['total_return'] = ret.get('rtot', 0) * 100
    except Exception:
        metrics['total_return'] = 0

    return metrics


def print_performance_report(results):
    """格式化输出回测绩效报告（命令行用）"""
    metrics = get_performance_metrics(results)
    print_performance_report_from_metrics(metrics)


def print_performance_report_from_metrics(metrics):
    """根据绩效指标字典格式化输出报告"""
    logger.info(f'\n{"="*50}')
    logger.info(f'  📊 回测绩效报告 - 信号质量评估')
    logger.info(f'{"="*50}')

    logger.info(f'  总信号数:   {metrics.get("total_trades", 0)}')
    logger.info(f'  盈利次数:   {metrics.get("won", 0)}')
    logger.info(f'  亏损次数:   {metrics.get("lost", 0)}')
    logger.info(f'  胜率:       {metrics.get("win_rate", 0):.1f}%')
    logger.info(f'  盈亏比:     {metrics.get("profit_ratio", 0):.2f}')

    max_dd = metrics.get('max_drawdown', 0)
    logger.info(f'  最大回撤:   {max_dd:.2f}%')

    sharpe = metrics.get('sharpe_ratio', None)
    sharpe_str = f'{sharpe:.4f}' if sharpe is not None else 'N/A'
    logger.info(f'  夏普率:     {sharpe_str}')

    total_return = metrics.get('total_return', 0)
    logger.info(f'  总收益率:   {total_return:.2f}%')

    logger.info(f'{"="*50}\n')


# ============================================================
# 6. 回测主函数
# ============================================================
def run_backtest(config_override=None) -> dict:
    """运行回测引擎，返回结构化结果"""
    # 合并配置
    cfg = dict(CONFIG)
    if config_override:
        cfg.update(config_override)

    cerebro = bt.Cerebro()

    # 加载数据
    data_df = get_ma_data(
        symbol=cfg.get('symbol'),
        start_date=cfg.get('start_date'),
        end_date=cfg.get('end_date'),
        jump_filter_pct=cfg.get('jump_filter_pct', CONFIG['jump_filter_pct']),
    )

    # 数据长度保护，避免指标最小窗口导致 Backtrader 内部索引异常
    min_required_bars = max(
        int(cfg.get('ma_period', 20)),
        int(cfg.get('atr_period', 14)),
        20,  # vol_period 默认值
    ) + 1
    if len(data_df) < min_required_bars:
        raise RuntimeError(
            f'历史数据不足: 至少需要 {min_required_bars} 根K线，当前仅 {len(data_df)} 根。'
            f'请扩大时间范围或缩短指标周期。'
        )

    data = bt.feeds.PandasData(dataname=data_df)
    cerebro.adddata(data)

    # 策略参数覆盖
    strategy_kwargs = {}
    if 'ma_period' in cfg:
        strategy_kwargs['ma_period'] = cfg['ma_period']
    if 'atr_period' in cfg:
        strategy_kwargs['atr_period'] = cfg['atr_period']
    if 'atr_stop_multiplier' in cfg:
        strategy_kwargs['atr_stop_multiplier'] = cfg['atr_stop_multiplier']
    if 'stop_loss' in cfg:
        strategy_kwargs['stop_loss'] = cfg['stop_loss'] / 100 if cfg['stop_loss'] > 1 else cfg['stop_loss']
    if 'risk_per_trade' in cfg:
        strategy_kwargs['risk_per_trade'] = cfg['risk_per_trade'] / 100 if cfg['risk_per_trade'] > 1 else cfg['risk_per_trade']
    if 'trail_atr_multiplier' in cfg:
        strategy_kwargs['trail_atr_multiplier'] = cfg['trail_atr_multiplier']
    cerebro.addstrategy(MA_Procurement_Strategy, **strategy_kwargs)

    # 资金与交易参数
    cerebro.broker.setcash(cfg['initial_cash'])
    cerebro.broker.setcommission(
        commission=cfg['commission'],
        margin=cfg['margin'],
        mult=cfg['mult'])
    cerebro.broker.set_slippage_fixed(cfg['slippage'])

    # 添加分析器
    cerebro.addanalyzer(bt.analyzers.SharpeRatio, _name='sharpe_ratio')
    cerebro.addanalyzer(bt.analyzers.DrawDown, _name='drawdown')
    cerebro.addanalyzer(bt.analyzers.TradeAnalyzer, _name='trade_analyzer')
    cerebro.addanalyzer(bt.analyzers.Returns, _name='returns')

    logger.info(f'回测开始本金: {cerebro.broker.getvalue():.2f}')
    results = cerebro.run()
    logger.info(f'回测结束资产: {cerebro.broker.getvalue():.2f}')

    strat = results[0]
    equity_curve = pd.Series(strat.equity_curve)

    return {
        'signals': strat.signal_records,
        'metrics': get_performance_metrics(results),
        'equity_curve': equity_curve,
        'ohlcv': data_df,
        'final_value': cerebro.broker.getvalue(),
        'initial_cash': cfg['initial_cash'],
        'trade_history': strat.trade_history,
        'cerebro': cerebro,
    }


# ============================================================
# 7. 程序入口
# ============================================================
if __name__ == '__main__':
    setup_logging(enable_file=True)
    # 确保 results 目录存在
    os.makedirs('results', exist_ok=True)
    # 运行回测
    result = run_backtest()
    # 输出绩效报告
    print_performance_report_from_metrics(result['metrics'])
    # 画图显示
    try:
        result['cerebro'].plot(style='candlestick')
    except Exception as e:
        logger.warning(f'图表绘制跳过（可能无图形界面）: {e}')
