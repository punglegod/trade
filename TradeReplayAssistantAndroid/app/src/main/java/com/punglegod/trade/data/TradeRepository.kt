package com.punglegod.trade.data

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.punglegod.trade.domain.ReportService
import com.punglegod.trade.domain.StatsRangeWindow
import com.punglegod.trade.domain.TradeDraft
import com.punglegod.trade.domain.TradeSnapshot
import com.punglegod.trade.domain.TradeSummary
import com.punglegod.trade.domain.TradeDirection
import com.punglegod.trade.domain.WeeklyReport
import java.util.UUID

class TradeRepository(
    private val store: TradeStore,
    private val reportService: ReportService = ReportService()
) {
    private var didBootstrap = false

    val trades = mutableStateListOf<TradeSnapshot>()

    var selectedSymbol by mutableStateOf("全部")
    var selectedTag by mutableStateOf("全部")

    val availableSymbols: List<String>
        get() = listOf("全部") + trades
            .filter { !it.isDeleted }
            .map { it.symbol }
            .filter { it.isNotBlank() }
            .distinct()
            .sorted()

    val availableTags: List<String>
        get() = listOf("全部") + trades
            .filter { !it.isDeleted }
            .map { it.strategyTag }
            .filter { it.isNotBlank() }
            .distinct()
            .sorted()

    val filteredTrades: List<TradeSnapshot>
        get() = trades
            .filter { !it.isDeleted }
            .filter { selectedSymbol == "全部" || it.symbol == selectedSymbol }
            .filter { selectedTag == "全部" || it.strategyTag == selectedTag }
            .sortedByDescending { it.openTimeMillis }

    suspend fun bootstrap() {
        if (didBootstrap) return

        val local = store.load()
        if (local.isEmpty()) {
            val seed = demoSeed()
            trades.addAll(seed)
            store.save(seed)
        } else {
            trades.addAll(local)
        }
        didBootstrap = true
    }

    suspend fun saveTrade(draft: TradeDraft, editingId: String? = null) {
        val now = System.currentTimeMillis()
        val existing = trades.firstOrNull { it.id == editingId }
        val id = editingId ?: UUID.randomUUID().toString()

        val snapshot = draft.toSnapshot(
            id = id,
            createdAtMillis = existing?.createdAtMillis ?: now,
            updatedAtMillis = now
        )

        val idx = trades.indexOfFirst { it.id == id }
        if (idx >= 0) {
            trades[idx] = snapshot
        } else {
            trades.add(snapshot)
        }

        persist()
    }

    suspend fun deleteTrade(id: String) {
        val now = System.currentTimeMillis()
        val idx = trades.indexOfFirst { it.id == id }
        if (idx < 0) return

        val target = trades[idx]
        trades[idx] = target.copy(
            updatedAtMillis = now,
            deletedAtMillis = now
        )

        persist()
    }

    fun summary(window: StatsRangeWindow, referenceMillis: Long = System.currentTimeMillis()): TradeSummary {
        return reportService.generateSummary(trades, window, referenceMillis)
    }

    fun weeklyReport(referenceMillis: Long = System.currentTimeMillis()): WeeklyReport {
        return reportService.generateWeeklyReport(trades, referenceMillis)
    }

    private suspend fun persist() {
        store.save(trades.toList())
    }

    companion object {
        fun demoSeed(referenceMillis: Long = System.currentTimeMillis()): List<TradeSnapshot> {
            val hour = 60L * 60 * 1_000
            val day = 24L * hour

            return listOf(
                TradeSnapshot(
                    id = UUID.randomUUID().toString(),
                    symbol = "AAPL",
                    direction = TradeDirection.LONG,
                    openTimeMillis = referenceMillis - day * 5 + hour * 10,
                    closeTimeMillis = referenceMillis - day * 5 + hour * 11,
                    openPrice = 188.2,
                    closePrice = 190.1,
                    positionSize = 100.0,
                    fee = 8.0,
                    pnl = 182.0,
                    strategyTag = "突破",
                    mistakeTag = "",
                    notes = "量价齐升后跟随，止盈执行良好。",
                    createdAtMillis = referenceMillis - day * 5,
                    updatedAtMillis = referenceMillis - day * 5,
                    deletedAtMillis = null
                ),
                TradeSnapshot(
                    id = UUID.randomUUID().toString(),
                    symbol = "TSLA",
                    direction = TradeDirection.SHORT,
                    openTimeMillis = referenceMillis - day * 3 + hour * 9,
                    closeTimeMillis = referenceMillis - day * 3 + hour * 10,
                    openPrice = 171.5,
                    closePrice = 173.0,
                    positionSize = 80.0,
                    fee = 7.0,
                    pnl = -127.0,
                    strategyTag = "回落",
                    mistakeTag = "止损迟疑",
                    notes = "触发止损后仍犹豫，扩大亏损。",
                    createdAtMillis = referenceMillis - day * 3,
                    updatedAtMillis = referenceMillis - day * 3,
                    deletedAtMillis = null
                ),
                TradeSnapshot(
                    id = UUID.randomUUID().toString(),
                    symbol = "NVDA",
                    direction = TradeDirection.LONG,
                    openTimeMillis = referenceMillis - day + hour * 13,
                    closeTimeMillis = referenceMillis - day + hour * 14,
                    openPrice = 943.0,
                    closePrice = 951.8,
                    positionSize = 20.0,
                    fee = 6.0,
                    pnl = 170.0,
                    strategyTag = "趋势",
                    mistakeTag = "",
                    notes = "顺势加仓后分批止盈，执行稳定。",
                    createdAtMillis = referenceMillis - day,
                    updatedAtMillis = referenceMillis - day,
                    deletedAtMillis = null
                )
            )
        }
    }
}
