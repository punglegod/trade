package com.punglegod.trade

import com.punglegod.trade.domain.ReportService
import com.punglegod.trade.domain.StatsRangeWindow
import com.punglegod.trade.domain.TradeDirection
import com.punglegod.trade.domain.TradeSnapshot
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.UUID

class ReportServiceTest {
    private val service = ReportService()

    @Test
    fun generateSummary_calculatesCoreMetrics() {
        val now = System.currentTimeMillis()
        val hour = 60L * 60 * 1_000

        val trades = listOf(
            makeTrade(now - hour * 8, 100.0),
            makeTrade(now - hour * 6, -50.0),
            makeTrade(now - hour * 2, 30.0)
        )

        val summary = service.generateSummary(
            trades = trades,
            window = StatsRangeWindow.LAST_7_DAYS,
            referenceMillis = now
        )

        assertEquals(3, summary.totalTrades)
        assertEquals(80.0, summary.totalPnL, 0.0001)
        assertEquals(2.0 / 3.0, summary.winRate, 0.0001)
        assertEquals(65.0, summary.averageWin, 0.0001)
        assertEquals(50.0, summary.averageLoss, 0.0001)
    }

    @Test
    fun generateWeeklyReport_returnsFallback_whenNoTrades() {
        val report = service.generateWeeklyReport(emptyList(), System.currentTimeMillis())
        assertEquals(0, report.summary.totalTrades)
        assertTrue(report.goodPractices.isNotEmpty())
        assertTrue(report.improvementAreas.isNotEmpty())
        assertTrue(report.nextWeekActions.isNotEmpty())
    }

    private fun makeTrade(closeMillis: Long, pnl: Double): TradeSnapshot {
        val openMillis = closeMillis - 3_600_000
        return TradeSnapshot(
            id = UUID.randomUUID().toString(),
            symbol = "AAPL",
            direction = TradeDirection.LONG,
            openTimeMillis = openMillis,
            closeTimeMillis = closeMillis,
            openPrice = 100.0,
            closePrice = 101.0,
            positionSize = 1.0,
            fee = 0.0,
            pnl = pnl,
            strategyTag = "趋势",
            mistakeTag = "",
            notes = "",
            createdAtMillis = openMillis,
            updatedAtMillis = closeMillis,
            deletedAtMillis = null
        )
    }
}
