package com.punglegod.trade.domain

class ReportService {
    fun generateSummary(
        trades: List<TradeSnapshot>,
        window: StatsRangeWindow,
        referenceMillis: Long
    ): TradeSummary {
        val start = window.startMillis(referenceMillis)
        val filtered = trades
            .asSequence()
            .filter { !it.isDeleted }
            .filter { it.closeTimeMillis in start..referenceMillis }
            .sortedBy { it.closeTimeMillis }
            .toList()

        if (filtered.isEmpty()) {
            return TradeSummary.Empty
        }

        val wins = filtered.filter { it.pnl > 0 }
        val losses = filtered.filter { it.pnl < 0 }

        val totalPnL = filtered.sumOf { it.pnl }
        val avgWin = if (wins.isEmpty()) 0.0 else wins.sumOf { it.pnl } / wins.size
        val avgLoss = if (losses.isEmpty()) 0.0 else losses.sumOf { kotlin.math.abs(it.pnl) } / losses.size

        val totalProfit = wins.sumOf { it.pnl }
        val totalLoss = losses.sumOf { kotlin.math.abs(it.pnl) }

        var running = 0.0
        var peak = 0.0
        var maxDrawdown = 0.0
        filtered.forEach {
            running += it.pnl
            peak = kotlin.math.max(peak, running)
            maxDrawdown = kotlin.math.max(maxDrawdown, peak - running)
        }

        return TradeSummary(
            totalTrades = filtered.size,
            winRate = wins.size.toDouble() / filtered.size.toDouble(),
            totalPnL = totalPnL,
            averageWin = avgWin,
            averageLoss = avgLoss,
            profitFactor = if (totalLoss == 0.0) totalProfit else totalProfit / totalLoss,
            maxDrawdown = maxDrawdown
        )
    }

    fun generateWeeklyReport(
        trades: List<TradeSnapshot>,
        referenceMillis: Long
    ): WeeklyReport {
        val dayMillis = 24L * 60 * 60 * 1_000
        val weekStart = referenceMillis - (6 * dayMillis)
        val weekEnd = referenceMillis

        val summary = generateSummary(
            trades = trades,
            window = StatsRangeWindow.LAST_7_DAYS,
            referenceMillis = referenceMillis
        )

        if (summary.totalTrades == 0) {
            return WeeklyReport.empty(referenceMillis)
        }

        val weekTrades = trades
            .filter { !it.isDeleted }
            .filter { it.closeTimeMillis in weekStart..weekEnd }

        val goodPractices = weekTrades
            .filter { it.pnl > 0 }
            .map { it.strategyTag }
            .toLabeledTop3(
                fallback = listOf("执行了既定止盈规则", "保持了仓位控制", "记录了复盘笔记")
            )

        val improvementAreas = weekTrades
            .filter { it.pnl < 0 }
            .map { if (it.mistakeTag.isBlank()) "出场纪律" else it.mistakeTag }
            .toLabeledTop3(
                fallback = listOf("减少冲动开仓", "严格执行止损", "收敛交易频率")
            )

        val nextActions = improvementAreas.map { "针对${it}设定明确触发条件并盘后打分" }

        return WeeklyReport(
            weekStartMillis = weekStart,
            weekEndMillis = weekEnd,
            summary = summary,
            goodPractices = goodPractices,
            improvementAreas = improvementAreas,
            nextWeekActions = nextActions
        )
    }
}
