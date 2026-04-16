package com.punglegod.trade

import com.punglegod.trade.data.InMemoryTradeStore
import com.punglegod.trade.data.TradeRepository
import com.punglegod.trade.domain.StatsRangeWindow
import com.punglegod.trade.domain.TradeDirection
import com.punglegod.trade.domain.TradeDraft
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Test

class TradeRepositoryFlowTest {
    @Test
    fun addTrade_updatesStatsAndWeeklyReport() = runBlocking {
        val repository = TradeRepository(InMemoryTradeStore(seed = emptyList()))
        repository.bootstrap()

        val now = System.currentTimeMillis()
        repository.saveTrade(
            TradeDraft(
                symbol = "AAPL",
                direction = TradeDirection.LONG,
                openTimeMillis = now - 7_200_000,
                closeTimeMillis = now - 3_600_000,
                openPrice = 100.0,
                closePrice = 110.0,
                positionSize = 1.0,
                fee = 0.0,
                strategyTag = "趋势",
                notes = "test"
            )
        )

        val summary = repository.summary(StatsRangeWindow.LAST_7_DAYS, now)
        val report = repository.weeklyReport(now)

        assertEquals(4, summary.totalTrades)
        assertEquals(4, report.summary.totalTrades)
    }
}
