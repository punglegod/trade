package com.punglegod.trade.domain

import kotlinx.serialization.Serializable
import kotlin.math.abs
import kotlin.math.max

@Serializable
enum class TradeDirection {
    LONG,
    SHORT;

    val label: String
        get() = when (this) {
            LONG -> "做多"
            SHORT -> "做空"
        }
}

@Serializable
data class TradeSnapshot(
    val id: String,
    val symbol: String,
    val direction: TradeDirection,
    val openTimeMillis: Long,
    val closeTimeMillis: Long,
    val openPrice: Double,
    val closePrice: Double,
    val positionSize: Double,
    val fee: Double,
    val pnl: Double,
    val strategyTag: String,
    val mistakeTag: String,
    val notes: String,
    val createdAtMillis: Long,
    val updatedAtMillis: Long,
    val deletedAtMillis: Long? = null
) {
    val isDeleted: Boolean get() = deletedAtMillis != null
    val holdingMinutes: Int get() = max(((closeTimeMillis - openTimeMillis) / 60_000).toInt(), 0)
}

@Serializable
data class TradeDraft(
    val symbol: String = "",
    val direction: TradeDirection = TradeDirection.LONG,
    val openTimeMillis: Long = System.currentTimeMillis(),
    val closeTimeMillis: Long = System.currentTimeMillis(),
    val openPrice: Double = 0.0,
    val closePrice: Double = 0.0,
    val positionSize: Double = 1.0,
    val fee: Double = 0.0,
    val strategyTag: String = "趋势",
    val mistakeTag: String = "",
    val notes: String = ""
) {
    fun toSnapshot(id: String, createdAtMillis: Long, updatedAtMillis: Long): TradeSnapshot {
        val directionMultiplier = if (direction == TradeDirection.LONG) 1.0 else -1.0
        val gross = (closePrice - openPrice) * positionSize * directionMultiplier
        val normalizedSymbol = symbol.trim().uppercase()

        return TradeSnapshot(
            id = id,
            symbol = normalizedSymbol,
            direction = direction,
            openTimeMillis = openTimeMillis,
            closeTimeMillis = closeTimeMillis,
            openPrice = openPrice,
            closePrice = closePrice,
            positionSize = positionSize,
            fee = fee,
            pnl = gross - fee,
            strategyTag = strategyTag.trim(),
            mistakeTag = mistakeTag.trim(),
            notes = notes.trim(),
            createdAtMillis = createdAtMillis,
            updatedAtMillis = updatedAtMillis,
            deletedAtMillis = null
        )
    }
}

enum class StatsRangeWindow(val label: String) {
    LAST_7_DAYS("近7天"),
    LAST_30_DAYS("近30天"),
    YEAR_TO_DATE("年内");

    fun startMillis(referenceMillis: Long): Long {
        val dayMillis = 24L * 60 * 60 * 1_000
        return when (this) {
            LAST_7_DAYS -> referenceMillis - (6 * dayMillis)
            LAST_30_DAYS -> referenceMillis - (29 * dayMillis)
            YEAR_TO_DATE -> {
                val cal = java.util.Calendar.getInstance().apply { timeInMillis = referenceMillis }
                cal.set(java.util.Calendar.MONTH, java.util.Calendar.JANUARY)
                cal.set(java.util.Calendar.DAY_OF_MONTH, 1)
                cal.set(java.util.Calendar.HOUR_OF_DAY, 0)
                cal.set(java.util.Calendar.MINUTE, 0)
                cal.set(java.util.Calendar.SECOND, 0)
                cal.set(java.util.Calendar.MILLISECOND, 0)
                cal.timeInMillis
            }
        }
    }
}

data class TradeSummary(
    val totalTrades: Int,
    val winRate: Double,
    val totalPnL: Double,
    val averageWin: Double,
    val averageLoss: Double,
    val profitFactor: Double,
    val maxDrawdown: Double
) {
    companion object {
        val Empty = TradeSummary(
            totalTrades = 0,
            winRate = 0.0,
            totalPnL = 0.0,
            averageWin = 0.0,
            averageLoss = 0.0,
            profitFactor = 0.0,
            maxDrawdown = 0.0
        )
    }
}

data class WeeklyReport(
    val weekStartMillis: Long,
    val weekEndMillis: Long,
    val summary: TradeSummary,
    val goodPractices: List<String>,
    val improvementAreas: List<String>,
    val nextWeekActions: List<String>
) {
    companion object {
        fun empty(referenceMillis: Long): WeeklyReport {
            val dayMillis = 24L * 60 * 60 * 1_000
            return WeeklyReport(
                weekStartMillis = referenceMillis - (6 * dayMillis),
                weekEndMillis = referenceMillis,
                summary = TradeSummary.Empty,
                goodPractices = listOf("本周暂无交易数据"),
                improvementAreas = listOf("先完成至少 5 笔可复盘交易"),
                nextWeekActions = listOf("交易结束后 10 分钟内填写复盘记录")
            )
        }
    }
}

fun List<String>.toLabeledTop3(fallback: List<String>): List<String> {
    val clean = map { it.trim() }.filter { it.isNotEmpty() }
    if (clean.isEmpty()) return fallback
    return clean.groupingBy { it }
        .eachCount()
        .entries
        .sortedWith(compareByDescending<Map.Entry<String, Int>> { it.value }.thenBy { it.key })
        .take(3)
        .map { it.key }
}

fun Double.formatSignedPnL(): String {
    val rounded = "%.2f".format(abs(this))
    return if (this >= 0) "+$rounded" else "-$rounded"
}
