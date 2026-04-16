package com.punglegod.trade.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.punglegod.trade.data.TradeRepository
import com.punglegod.trade.domain.StatsRangeWindow
import com.punglegod.trade.ui.components.GlassCard
import com.punglegod.trade.ui.components.PillSegmentedControl
import com.punglegod.trade.ui.components.format2
import com.punglegod.trade.ui.components.formatPct

@Composable
fun StatsScreen(repository: TradeRepository) {
    var window by rememberSaveable { mutableStateOf(StatsRangeWindow.LAST_7_DAYS) }
    val summary = repository.summary(window)

    Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)) {
        Text("统计看板", style = MaterialTheme.typography.headlineSmall)
        Text("时间窗内核心指标", style = MaterialTheme.typography.bodyMedium)

        Spacer(modifier = Modifier.height(12.dp))

        PillSegmentedControl(
            items = StatsRangeWindow.entries,
            selected = window,
            label = { it.label },
            onSelect = { window = it }
        )

        Spacer(modifier = Modifier.height(12.dp))

        MetricRow("总笔数", summary.totalTrades.toString(), "胜率", summary.winRate.formatPct())
        MetricRow("总盈亏", summary.totalPnL.format2(), "平均盈利", summary.averageWin.format2())
        MetricRow("平均亏损", summary.averageLoss.format2(), "Profit Factor", summary.profitFactor.format2())
        MetricRow("最大回撤", summary.maxDrawdown.format2(), "当前筛选", repository.filteredTrades.size.toString())
    }
}

@Composable
private fun MetricRow(leftLabel: String, leftValue: String, rightLabel: String, rightValue: String) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        MetricCard(modifier = Modifier.weight(1f), title = leftLabel, value = leftValue)
        MetricCard(modifier = Modifier.weight(1f), title = rightLabel, value = rightValue)
    }
    Spacer(modifier = Modifier.height(10.dp))
}

@Composable
private fun MetricCard(modifier: Modifier = Modifier, title: String, value: String) {
    GlassCard(modifier = modifier) {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(title, style = MaterialTheme.typography.labelMedium)
            Text(value, style = MaterialTheme.typography.titleLarge)
        }
    }
}
