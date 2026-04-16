package com.punglegod.trade.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.punglegod.trade.data.TradeRepository
import com.punglegod.trade.ui.components.FilterChip
import com.punglegod.trade.ui.components.GlassCard
import com.punglegod.trade.ui.components.format2
import com.punglegod.trade.ui.components.formatDateOnly
import com.punglegod.trade.ui.components.formatPct

@Composable
fun ReportScreen(repository: TradeRepository) {
    val report = repository.weeklyReport()

    Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)) {
        Text("周报", style = MaterialTheme.typography.headlineSmall)
        Text("${report.weekStartMillis.formatDateOnly()} - ${report.weekEndMillis.formatDateOnly()}")

        Spacer(modifier = Modifier.height(12.dp))

        GlassCard {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("本周摘要", style = MaterialTheme.typography.titleMedium)
                Text("总笔数: ${report.summary.totalTrades}")
                Text("胜率: ${report.summary.winRate.formatPct()}")
                Text("总盈亏: ${report.summary.totalPnL.format2()}")
                Text("最大回撤: ${report.summary.maxDrawdown.format2()}")
            }
        }

        Spacer(modifier = Modifier.height(12.dp))
        Text("做得好", style = MaterialTheme.typography.titleMedium)
        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            items(report.goodPractices) { item ->
                FilterChip(label = item, selected = true, onClick = {})
            }
        }

        Spacer(modifier = Modifier.height(10.dp))
        Text("待改进", style = MaterialTheme.typography.titleMedium)
        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            items(report.improvementAreas) { item ->
                FilterChip(label = item, selected = false, onClick = {})
            }
        }

        Spacer(modifier = Modifier.height(10.dp))
        Text("下周行动", style = MaterialTheme.typography.titleMedium)
        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            items(report.nextWeekActions) { item ->
                FilterChip(label = item, selected = true, onClick = {})
            }
        }
    }
}
