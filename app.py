"""
甲醇期货交易信号可视化平台
Apple 风格设计 - 液态玻璃 · 药丸形状 · 磨砂质感
"""

import logging
logging.basicConfig(level=logging.WARNING)

import streamlit as st
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import pandas as pd
from datetime import date

from main import run_backtest, CONFIG

# ============================================================
# Apple 风格 CSS 定制
# ============================================================
def apply_apple_style():
    """注入 Apple 风格 CSS"""
    st.markdown("""
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');

    * {
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    }

    /* 主背景 - 柔和的动态渐变 */
    .stApp {
        background: linear-gradient(135deg, #f5f7fa 0%, #e4e9f2 50%, #f0f4f8 100%);
    }

    /* 液态玻璃卡片效果 */
    .glass-card {
        background: rgba(255, 255, 255, 0.72);
        backdrop-filter: blur(20px) saturate(180%);
        -webkit-backdrop-filter: blur(20px) saturate(180%);
        border-radius: 24px;
        border: 1px solid rgba(255, 255, 255, 0.5);
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.06),
                    0 2px 8px rgba(0, 0, 0, 0.04),
                    inset 0 1px 0 rgba(255, 255, 255, 0.8);
        padding: 24px;
        margin-bottom: 20px;
        transition: transform 0.3s ease, box-shadow 0.3s ease;
    }

    .glass-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 12px 40px rgba(0, 0, 0, 0.08),
                    0 4px 12px rgba(0, 0, 0, 0.05),
                    inset 0 1px 0 rgba(255, 255, 255, 0.9);
    }

    /* 药丸形状按钮 */
    .stButton > button {
        background: linear-gradient(135deg, #007AFF 0%, #0051D5 100%);
        color: white;
        border: none;
        border-radius: 9999px !important;
        padding: 12px 32px;
        font-weight: 600;
        font-size: 15px;
        letter-spacing: -0.01em;
        box-shadow: 0 4px 16px rgba(0, 122, 255, 0.35),
                    0 2px 4px rgba(0, 0, 0, 0.1);
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .stButton > button:hover {
        transform: scale(1.02);
        box-shadow: 0 6px 24px rgba(0, 122, 255, 0.45),
                    0 3px 6px rgba(0, 0, 0, 0.12);
        background: linear-gradient(135deg, #007AFF 0%, #0062E0 100%);
    }

    .stButton > button:active {
        transform: scale(0.98);
    }

    /* 药丸标签 */
    .pill-tag {
        display: inline-flex;
        align-items: center;
        padding: 6px 16px;
        border-radius: 9999px;
        font-size: 13px;
        font-weight: 500;
        letter-spacing: -0.01em;
        backdrop-filter: blur(10px);
        -webkit-backdrop-filter: blur(10px);
        transition: all 0.2s ease;
    }

    .pill-tag-blue {
        background: rgba(0, 122, 255, 0.12);
        color: #007AFF;
        border: 1px solid rgba(0, 122, 255, 0.2);
    }

    .pill-tag-green {
        background: rgba(52, 199, 89, 0.12);
        color: #34C759;
        border: 1px solid rgba(52, 199, 89, 0.2);
    }

    .pill-tag-red {
        background: rgba(255, 59, 48, 0.12);
        color: #FF3B30;
        border: 1px solid rgba(255, 59, 48, 0.2);
    }

    .pill-tag-gray {
        background: rgba(142, 142, 147, 0.12);
        color: #8E8E93;
        border: 1px solid rgba(142, 142, 147, 0.2);
    }

    /* 指标卡片 */
    .metric-card {
        background: rgba(255, 255, 255, 0.6);
        backdrop-filter: blur(16px);
        -webkit-backdrop-filter: blur(16px);
        border-radius: 20px;
        padding: 20px;
        text-align: center;
        border: 1px solid rgba(255, 255, 255, 0.5);
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.04);
        transition: all 0.3s ease;
    }

    .metric-card:hover {
        background: rgba(255, 255, 255, 0.8);
        transform: translateY(-2px);
    }

    .metric-value {
        font-size: 28px;
        font-weight: 700;
        color: #1D1D1F;
        letter-spacing: -0.02em;
    }

    .metric-label {
        font-size: 13px;
        color: #8E8E93;
        font-weight: 500;
        margin-top: 4px;
        text-transform: uppercase;
        letter-spacing: 0.02em;
    }

    .metric-positive {
        color: #34C759;
    }

    .metric-negative {
        color: #FF3B30;
    }

    /* 侧边栏玻璃效果 */
    [data-testid="stSidebar"] {
        background: rgba(255, 255, 255, 0.8) !important;
        backdrop-filter: blur(24px) saturate(180%);
        -webkit-backdrop-filter: blur(24px) saturate(180%);
        border-right: 1px solid rgba(255, 255, 255, 0.6);
    }

    [data-testid="stSidebar"] .block-container {
        padding: 24px 20px;
    }

    /* 滑块样式 */
    .stSlider [data-testid="stThumbValue"] {
        background: #007AFF;
        border-radius: 9999px;
        padding: 4px 12px;
        font-weight: 600;
        font-size: 12px;
    }

    /* 输入框样式 */
    .stTextInput > div > div > input,
    .stNumberInput > div > div > input {
        border-radius: 12px;
        border: 1px solid rgba(0, 0, 0, 0.08);
        background: rgba(255, 255, 255, 0.8);
        padding: 12px 16px;
        font-size: 15px;
        transition: all 0.2s ease;
    }

    .stTextInput > div > div > input:focus,
    .stNumberInput > div > div > input:focus {
        border-color: #007AFF;
        box-shadow: 0 0 0 3px rgba(0, 122, 255, 0.15);
    }

    /* 日期选择器 */
    .stDateInput > div > div > input {
        border-radius: 12px;
        border: 1px solid rgba(0, 0, 0, 0.08);
        background: rgba(255, 255, 255, 0.8);
    }

    /* 标题样式 */
    h1 {
        font-size: 32px !important;
        font-weight: 700 !important;
        letter-spacing: -0.025em !important;
        color: #1D1D1F !important;
        margin-bottom: 8px !important;
    }

    h2 {
        font-size: 22px !important;
        font-weight: 600 !important;
        letter-spacing: -0.02em !important;
        color: #1D1D1F !important;
    }

    h3 {
        font-size: 17px !important;
        font-weight: 600 !important;
        color: #3A3A3C !important;
    }

    /* 副标题/描述 */
    .subtitle {
        font-size: 15px;
        color: #8E8E93;
        font-weight: 400;
        margin-bottom: 24px;
    }

    /* 分隔线 */
    hr {
        border: none;
        height: 1px;
        background: linear-gradient(90deg, transparent, rgba(0, 0, 0, 0.06), transparent);
        margin: 24px 0;
    }

    /* 数据表格 */
    .stDataFrame {
        border-radius: 16px;
        overflow: hidden;
        border: 1px solid rgba(0, 0, 0, 0.06);
    }

    /* 成功/错误消息 */
    .stSuccess, .stError, .stInfo {
        border-radius: 16px;
        backdrop-filter: blur(10px);
        border: 1px solid rgba(255, 255, 255, 0.5);
    }

    .stSuccess {
        background: rgba(52, 199, 89, 0.12) !important;
        border-color: rgba(52, 199, 89, 0.2) !important;
    }

    .stError {
        background: rgba(255, 59, 48, 0.12) !important;
        border-color: rgba(255, 59, 48, 0.2) !important;
    }

    /* Spinner */
    .stSpinner > div {
        border-color: #007AFF transparent transparent !important;
    }

    /* 隐藏默认元素 */
    #MainMenu {visibility: hidden;}
    footer {visibility: hidden;}
    header {visibility: hidden;}

    /* 滚动条样式 */
    ::-webkit-scrollbar {
        width: 8px;
        height: 8px;
    }

    ::-webkit-scrollbar-track {
        background: transparent;
    }

    ::-webkit-scrollbar-thumb {
        background: rgba(0, 0, 0, 0.15);
        border-radius: 9999px;
    }

    ::-webkit-scrollbar-thumb:hover {
        background: rgba(0, 0, 0, 0.25);
    }
    </style>
    """, unsafe_allow_html=True)


# ============================================================
# Apple 风格指标卡片
# ============================================================
def metric_card(title, value, delta=None, is_positive=None):
    """渲染 Apple 风格指标卡片"""
    delta_html = ""
    if delta is not None:
        color_class = ""
        if is_positive is True:
            color_class = "metric-positive"
        elif is_positive is False:
            color_class = "metric-negative"
        delta_html = f'<div style="font-size: 13px; margin-top: 4px;" class="{color_class}">{delta}</div>'

    return f"""
    <div class="metric-card">
        <div class="metric-value">{value}</div>
        <div class="metric-label">{title}</div>
        {delta_html}
    </div>
    """


# ============================================================
# Apple 风格药丸标签
# ============================================================
def pill_tag(text, variant="blue"):
    """渲染药丸标签"""
    return f'<span class="pill-tag pill-tag-{variant}">{text}</span>'


# ============================================================
# 页面配置
# ============================================================
st.set_page_config(
    page_title="甲醇期货交易信号系统",
    page_icon="📈",
    layout="wide",
    initial_sidebar_state="expanded"
)

# 应用 Apple 样式
apply_apple_style()

# 顶部标题区
st.markdown("""
<div style="text-align: center; margin-bottom: 32px;">
    <h1>📈 甲醇期货交易信号系统</h1>
    <div class="subtitle">智能回测分析平台 · Apple Design</div>
</div>
""", unsafe_allow_html=True)

# ============================================================
# 侧边栏 - 参数调节面板
# ============================================================
with st.sidebar:
    st.markdown("""
    <div style="margin-bottom: 24px;">
        <h3 style="margin: 0;">⚙️ 参数设置</h3>
        <div style="font-size: 13px; color: #8E8E93;">自定义您的回测策略</div>
    </div>
    """, unsafe_allow_html=True)

    # 品种配置
    st.markdown("<hr style='margin: 16px 0;'>", unsafe_allow_html=True)
    st.markdown("**品种配置**")
    symbol = st.text_input("品种代码", value="MA", label_visibility="collapsed",
                          placeholder="输入品种代码")

    col_date1, col_date2 = st.columns(2)
    with col_date1:
        start_date = st.date_input("起始日期", value=date(2024, 1, 1))
    with col_date2:
        end_date = st.date_input("结束日期", value=date(2025, 12, 31))

    # 策略参数
    st.markdown("<hr style='margin: 16px 0;'>", unsafe_allow_html=True)
    st.markdown("**策略参数**")

    ma_period = st.slider("MA周期", min_value=5, max_value=60, value=20)
    atr_period = st.slider("ATR周期", min_value=5, max_value=30, value=14)
    atr_stop_multiplier = st.slider("ATR止损倍数", min_value=0.5, max_value=5.0, step=0.1, value=2.0)
    trail_atr_multiplier = st.slider("移动止盈ATR倍数", min_value=1.0, max_value=8.0, step=0.1, value=3.0)
    stop_loss_pct = st.slider("固定止损%", min_value=1, max_value=10, value=3)
    jump_filter_pct = st.slider("异常跳空过滤阈值%", min_value=0.0, max_value=15.0, step=0.5, value=6.0)
    risk_per_trade_pct = st.slider("单笔风险仓位%", min_value=0.0, max_value=10.0, step=0.5, value=0.0)

    # 交易参数
    st.markdown("<hr style='margin: 16px 0;'>", unsafe_allow_html=True)
    st.markdown("**交易参数**")

    initial_cash = st.number_input("初始资金", value=10000.0, min_value=1000.0, step=1000.0)
    commission = st.number_input("手续费(元/手)", value=3.0, min_value=0.0, step=0.5)
    slippage = st.number_input("滑点(元)", value=1.0, min_value=0.0, step=0.5)

    # 开始回测按钮
    st.markdown("<div style='margin-top: 24px;'></div>", unsafe_allow_html=True)
    run_btn = st.button("🚀 开始回测", use_container_width=True)


# ============================================================
# 主区域
# ============================================================
if run_btn:
    config_override = {
        'symbol': symbol,
        'start_date': start_date.strftime('%Y%m%d'),
        'end_date': end_date.strftime('%Y%m%d'),
        'initial_cash': initial_cash,
        'commission': commission,
        'slippage': slippage,
        'ma_period': ma_period,
        'atr_period': atr_period,
        'atr_stop_multiplier': atr_stop_multiplier,
        'trail_atr_multiplier': trail_atr_multiplier,
        'stop_loss': stop_loss_pct,
        'jump_filter_pct': jump_filter_pct,
        'risk_per_trade': risk_per_trade_pct,
    }

    try:
        with st.spinner("⏳ 正在获取数据并运行回测，请稍候..."):
            result = run_backtest(config_override=config_override)

        st.success("✅ 回测完成！")

        # ========================================================
        # 信号仪表盘
        # ========================================================
        st.markdown("<h2>📊 信号仪表盘</h2>", unsafe_allow_html=True)

        ohlcv = result['ohlcv']
        ma = ohlcv['close'].rolling(window=ma_period).mean()

        # Apple 风格 K线图
        fig = make_subplots(
            rows=2, cols=1, shared_xaxes=True,
            row_heights=[0.7, 0.3],
            vertical_spacing=0.03,
            subplot_titles=("", "")
        )

        # 蜡烛图 - Apple 风格配色
        colors_up = '#34C759'   # Apple 绿色
        colors_down = '#FF3B30'  # Apple 红色

        fig.add_trace(go.Candlestick(
            x=ohlcv.index,
            open=ohlcv['open'],
            high=ohlcv['high'],
            low=ohlcv['low'],
            close=ohlcv['close'],
            name='K线',
            increasing_line_color=colors_up,
            increasing_fillcolor='rgba(52, 199, 89, 0.8)',
            decreasing_line_color=colors_down,
            decreasing_fillcolor='rgba(255, 59, 48, 0.8)',
        ), row=1, col=1)

        # MA 均线 - Apple 蓝色
        fig.add_trace(go.Scatter(
            x=ohlcv.index,
            y=ma,
            mode='lines',
            name=f'MA{ma_period}',
            line=dict(color='#007AFF', width=2),
        ), row=1, col=1)

        # 买入信号 - 药丸形状标记
        buy_signals = [s for s in result['signals'] if '买入' in s['type']]
        sell_signals = [s for s in result['signals'] if '卖出' in s['type']]

        if buy_signals:
            fig.add_trace(go.Scatter(
                x=[s['date'] for s in buy_signals],
                y=[float(s['price']) * 0.995 for s in buy_signals],
                mode='markers',
                name='买入信号',
                marker=dict(
                    symbol='circle',
                    size=14,
                    color='#34C759',
                    line=dict(color='white', width=2)
                ),
                text=[s.get('reason', '买入') for s in buy_signals],
                hovertemplate='<b>买入</b><br>日期: %{x}<br>价格: %{customdata}<br>原因: %{text}<extra></extra>',
                customdata=[s['price'] for s in buy_signals],
            ), row=1, col=1)

        if sell_signals:
            fig.add_trace(go.Scatter(
                x=[s['date'] for s in sell_signals],
                y=[float(s['price']) * 1.005 for s in sell_signals],
                mode='markers',
                name='卖出信号',
                marker=dict(
                    symbol='circle',
                    size=14,
                    color='#FF3B30',
                    line=dict(color='white', width=2)
                ),
                text=[s.get('reason', '卖出') for s in sell_signals],
                hovertemplate='<b>卖出</b><br>日期: %{x}<br>价格: %{customdata}<br>原因: %{text}<extra></extra>',
                customdata=[s['price'] for s in sell_signals],
            ), row=1, col=1)

        # 成交量柱状图
        vol_colors = [colors_up if c >= o else colors_down
                      for c, o in zip(ohlcv['close'], ohlcv['open'])]
        fig.add_trace(go.Bar(
            x=ohlcv.index,
            y=ohlcv['volume'],
            name='成交量',
            marker_color=vol_colors,
            opacity=0.6,
        ), row=2, col=1)

        # Apple 风格布局
        fig.update_layout(
            height=600,
            xaxis_rangeslider_visible=False,
            showlegend=True,
            legend=dict(
                orientation="h",
                yanchor="bottom",
                y=1.02,
                xanchor="right",
                x=1,
                bgcolor='rgba(255,255,255,0.7)',
                bordercolor='rgba(0,0,0,0.05)',
                borderwidth=1,
                font=dict(size=12)
            ),
            plot_bgcolor='rgba(0,0,0,0)',
            paper_bgcolor='rgba(0,0,0,0)',
            font=dict(family='Inter, sans-serif', size=13, color='#3A3A3C'),
            margin=dict(l=60, r=40, t=60, b=40),
        )

        # 坐标轴样式
        fig.update_xaxes(
            showgrid=True,
            gridwidth=1,
            gridcolor='rgba(0,0,0,0.05)',
            showline=False,
        )
        fig.update_yaxes(
            showgrid=True,
            gridwidth=1,
            gridcolor='rgba(0,0,0,0.05)',
            showline=False,
            title_text="价格",
            row=1, col=1
        )
        fig.update_yaxes(
            showgrid=True,
            gridwidth=1,
            gridcolor='rgba(0,0,0,0.05)',
            showline=False,
            title_text="成交量",
            row=2, col=1
        )

        st.plotly_chart(fig, use_container_width=True)

        # 信号明细表格
        st.markdown("<h3>📋 信号明细</h3>", unsafe_allow_html=True)
        if result['signals']:
            df_signals = pd.DataFrame(result['signals'])
            display_cols = ['date', 'type', 'price', 'ma', 'deviation', 'atr', 'volume_status', 'reason']
            df_display = df_signals[[c for c in display_cols if c in df_signals.columns]]
            df_display.columns = ['日期', '类型', '价格', '均线值', '偏离度', 'ATR', '量能', '原因']
            st.dataframe(df_display, use_container_width=True, hide_index=True)
        else:
            st.info("本次回测未产生任何交易信号。")

        # ========================================================
        # 绩效分析
        # ========================================================
        st.markdown("<h2>📈 绩效分析</h2>", unsafe_allow_html=True)
        metrics = result['metrics']

        # 指标卡片 - Apple 风格
        cols = st.columns(6)
        metric_data = [
            ("总收益率", f"{metrics.get('total_return', 0):.2f}%",
             metrics.get('total_return', 0) >= 0),
            ("夏普率", f"{metrics.get('sharpe_ratio', 0):.4f}" if metrics.get('sharpe_ratio') else "N/A",
             None),
            ("最大回撤", f"{metrics.get('max_drawdown', 0):.2f}%",
             False),
            ("胜率", f"{metrics.get('win_rate', 0):.1f}%",
             metrics.get('win_rate', 0) >= 50),
            ("盈亏比", f"{metrics.get('profit_ratio', 0):.2f}",
             metrics.get('profit_ratio', 0) >= 1),
            ("总交易次数", f"{metrics.get('total_trades', 0)}",
             None),
        ]

        for col, (label, value, is_pos) in zip(cols, metric_data):
            with col:
                st.markdown(metric_card(label, value, is_positive=is_pos), unsafe_allow_html=True)

        st.markdown("<div style='margin: 24px 0;'></div>", unsafe_allow_html=True)

        # 三张图表
        chart_col1, chart_col2, chart_col3 = st.columns(3)

        # 1. 资金曲线图 - Apple 风格渐变
        with chart_col1:
            st.markdown("<h3>💰 资金曲线</h3>", unsafe_allow_html=True)
            equity = result['equity_curve']
            if len(equity) > 0:
                fig_equity = go.Figure()

                # 渐变填充区域
                fig_equity.add_trace(go.Scatter(
                    x=equity.index if hasattr(equity.index, '__iter__') else list(equity.keys()),
                    y=equity.values,
                    mode='lines',
                    name='资产净值',
                    line=dict(color='#007AFF', width=2.5),
                    fill='tozeroy',
                    fillcolor='rgba(0, 122, 255, 0.1)',
                ))

                # 添加最终数值标签
                final_value = list(equity.values)[-1] if hasattr(equity.values, '__iter__') else list(equity.values())[-1]
                fig_equity.add_annotation(
                    x=1, y=final_value,
                    xref='paper',
                    text=f"¥{final_value:,.0f}",
                    showarrow=False,
                    font=dict(size=14, color='#007AFF', weight='bold'),
                    bgcolor='rgba(255,255,255,0.8)',
                    bordercolor='#007AFF',
                    borderwidth=1,
                    borderpad=4,
                    border-radius=8
                )

                fig_equity.update_layout(
                    xaxis_title="日期",
                    yaxis_title="资产净值",
                    height=350,
                    margin=dict(l=20, r=20, t=20, b=40),
                    plot_bgcolor='rgba(0,0,0,0)',
                    paper_bgcolor='rgba(0,0,0,0)',
                    font=dict(family='Inter, sans-serif', size=12),
                    showlegend=False,
                    xaxis=dict(showgrid=True, gridcolor='rgba(0,0,0,0.05)'),
                    yaxis=dict(showgrid=True, gridcolor='rgba(0,0,0,0.05)'),
                )
                st.plotly_chart(fig_equity, use_container_width=True)
            else:
                st.info("无资金曲线数据")

        # 2. 盈亏分布图
        with chart_col2:
            st.markdown("<h3>📊 盈亏分布</h3>", unsafe_allow_html=True)
            trade_history = result['trade_history']
            if trade_history:
                pnl_values = [t['pnl_comm'] for t in trade_history]
                pnl_colors = ['#34C759' if v >= 0 else '#FF3B30' for v in pnl_values]

                fig_pnl = go.Figure()
                fig_pnl.add_trace(go.Bar(
                    x=list(range(1, len(pnl_values) + 1)),
                    y=pnl_values,
                    marker_color=pnl_colors,
                    marker_line_width=0,
                    opacity=0.85,
                    name='盈亏',
                    text=[f"{v:.0f}" for v in pnl_values],
                    textposition='outside',
                    textfont=dict(size=10),
                ))

                fig_pnl.update_layout(
                    xaxis_title="交易序号",
                    yaxis_title="盈亏(元)",
                    height=350,
                    margin=dict(l=20, r=20, t=20, b=40),
                    plot_bgcolor='rgba(0,0,0,0)',
                    paper_bgcolor='rgba(0,0,0,0)',
                    font=dict(family='Inter, sans-serif', size=12),
                    showlegend=False,
                    xaxis=dict(showgrid=False),
                    yaxis=dict(showgrid=True, gridcolor='rgba(0,0,0,0.05)'),
                )
                st.plotly_chart(fig_pnl, use_container_width=True)
            else:
                st.info("无交易记录")

        # 3. 回撤曲线图
        with chart_col3:
            st.markdown("<h3>📉 回撤曲线</h3>", unsafe_allow_html=True)
            equity = result['equity_curve']
            if len(equity) > 0:
                running_max = equity.cummax()
                drawdown = (equity - running_max) / running_max * 100

                fig_dd = go.Figure()
                fig_dd.add_trace(go.Scatter(
                    x=drawdown.index if hasattr(drawdown.index, '__iter__') else list(drawdown.keys()),
                    y=drawdown.values,
                    mode='lines',
                    name='回撤%',
                    line=dict(color='#FF3B30', width=2),
                    fill='tozeroy',
                    fillcolor='rgba(255, 59, 48, 0.15)',
                ))

                fig_dd.update_layout(
                    xaxis_title="日期",
                    yaxis_title="回撤(%)",
                    height=350,
                    margin=dict(l=20, r=20, t=20, b=40),
                    plot_bgcolor='rgba(0,0,0,0)',
                    paper_bgcolor='rgba(0,0,0,0)',
                    font=dict(family='Inter, sans-serif', size=12),
                    showlegend=False,
                    xaxis=dict(showgrid=True, gridcolor='rgba(0,0,0,0.05)'),
                    yaxis=dict(showgrid=True, gridcolor='rgba(0,0,0,0.05)'),
                )
                st.plotly_chart(fig_dd, use_container_width=True)
            else:
                st.info("无回撤数据")

    except SystemExit as e:
        st.error(f"❌ 回测运行被中断：{e}")
    except Exception as e:
        st.error(f"❌ 回测运行出错：{e}")

else:
    # 初始状态 - 欢迎信息
    st.markdown("""
    <div style="
        background: rgba(255, 255, 255, 0.6);
        backdrop-filter: blur(20px);
        border-radius: 24px;
        padding: 48px;
        text-align: center;
        border: 1px solid rgba(255, 255, 255, 0.5);
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.06);
        margin-top: 40px;
    ">
        <div style="font-size: 64px; margin-bottom: 16px;">👈</div>
        <h2 style="margin-bottom: 12px;">欢迎使用甲醇期货交易信号系统</h2>
        <p style="color: #8E8E93; font-size: 16px; margin: 0;">
            请在左侧设置参数后点击「开始回测」运行分析
        </p>
    </div>
    """, unsafe_allow_html=True)
