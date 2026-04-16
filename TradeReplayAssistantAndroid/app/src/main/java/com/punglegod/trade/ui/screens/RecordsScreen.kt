package com.punglegod.trade.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.punglegod.trade.data.TradeRepository
import com.punglegod.trade.domain.TradeDirection
import com.punglegod.trade.domain.TradeDraft
import com.punglegod.trade.domain.formatSignedPnL
import com.punglegod.trade.ui.components.FilterChip
import com.punglegod.trade.ui.components.GlassCard
import com.punglegod.trade.ui.components.PillPrimaryButton
import com.punglegod.trade.ui.components.format2
import com.punglegod.trade.ui.components.formatDateTime
import kotlinx.coroutines.launch

@Composable
fun RecordsScreen(repository: TradeRepository) {
    val scope = rememberCoroutineScope()
    var showEditor by remember { mutableStateOf(false) }

    Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)) {
        Text("交易记录", style = MaterialTheme.typography.headlineSmall)
        Text(
            text = "共 ${repository.filteredTrades.size} 笔 · 先记录，再复盘",
            style = MaterialTheme.typography.bodyMedium
        )

        Spacer(modifier = Modifier.height(12.dp))

        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            items(repository.availableSymbols) { symbol ->
                FilterChip(
                    label = symbol,
                    selected = symbol == repository.selectedSymbol,
                    onClick = { repository.selectedSymbol = symbol }
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            items(repository.availableTags) { tag ->
                FilterChip(
                    label = tag,
                    selected = tag == repository.selectedTag,
                    onClick = { repository.selectedTag = tag }
                )
            }
        }

        Spacer(modifier = Modifier.height(10.dp))

        PillPrimaryButton(
            text = "新增交易",
            onClick = { showEditor = true }
        )

        Spacer(modifier = Modifier.height(12.dp))

        LazyColumn(
            contentPadding = PaddingValues(bottom = 120.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            items(repository.filteredTrades, key = { it.id }) { trade ->
                GlassCard {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("${trade.symbol} · ${trade.direction.label}", style = MaterialTheme.typography.titleMedium)
                            Text(
                                text = trade.pnl.formatSignedPnL(),
                                color = if (trade.pnl >= 0) androidx.compose.ui.graphics.Color(0xFF1E9B62) else androidx.compose.ui.graphics.Color(0xFFD64545),
                                style = MaterialTheme.typography.titleMedium
                            )
                        }

                        Text("开: ${trade.openPrice.format2()}  收: ${trade.closePrice.format2()}  手数: ${trade.positionSize.format2()}")
                        Text("策略: ${trade.strategyTag.ifBlank { "未标注" }}  错误: ${trade.mistakeTag.ifBlank { "无" }}")
                        Text("${trade.openTimeMillis.formatDateTime()} -> ${trade.closeTimeMillis.formatDateTime()}")

                        Text(
                            text = "删除",
                            color = androidx.compose.ui.graphics.Color(0xFFD64545),
                            modifier = Modifier.clickable {
                                scope.launch { repository.deleteTrade(trade.id) }
                            }
                        )
                    }
                }
            }
        }
    }

    if (showEditor) {
        TradeEditorDialog(
            onDismiss = { showEditor = false },
            onSave = { draft ->
                scope.launch {
                    repository.saveTrade(draft)
                    showEditor = false
                }
            }
        )
    }
}

@Composable
private fun TradeEditorDialog(
    onDismiss: () -> Unit,
    onSave: (TradeDraft) -> Unit
) {
    var symbol by remember { mutableStateOf("") }
    var openPrice by remember { mutableStateOf("100") }
    var closePrice by remember { mutableStateOf("101") }
    var positionSize by remember { mutableStateOf("1") }
    var fee by remember { mutableStateOf("0") }
    var strategyTag by remember { mutableStateOf("趋势") }
    var mistakeTag by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }
    var direction by remember { mutableStateOf(TradeDirection.LONG) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("新增交易") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(
                        label = "做多",
                        selected = direction == TradeDirection.LONG,
                        onClick = { direction = TradeDirection.LONG }
                    )
                    FilterChip(
                        label = "做空",
                        selected = direction == TradeDirection.SHORT,
                        onClick = { direction = TradeDirection.SHORT }
                    )
                }
                OutlinedTextField(value = symbol, onValueChange = { symbol = it }, label = { Text("标的") })
                OutlinedTextField(value = openPrice, onValueChange = { openPrice = it }, label = { Text("开仓价") })
                OutlinedTextField(value = closePrice, onValueChange = { closePrice = it }, label = { Text("平仓价") })
                OutlinedTextField(value = positionSize, onValueChange = { positionSize = it }, label = { Text("仓位") })
                OutlinedTextField(value = fee, onValueChange = { fee = it }, label = { Text("手续费") })
                OutlinedTextField(value = strategyTag, onValueChange = { strategyTag = it }, label = { Text("策略标签") })
                OutlinedTextField(value = mistakeTag, onValueChange = { mistakeTag = it }, label = { Text("错误标签") })
                OutlinedTextField(value = notes, onValueChange = { notes = it }, label = { Text("备注") })
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    val op = openPrice.toDoubleOrNull() ?: return@TextButton
                    val cp = closePrice.toDoubleOrNull() ?: return@TextButton
                    val ps = positionSize.toDoubleOrNull() ?: return@TextButton
                    val f = fee.toDoubleOrNull() ?: 0.0
                    if (symbol.isBlank()) return@TextButton

                    onSave(
                        TradeDraft(
                            symbol = symbol,
                            direction = direction,
                            openPrice = op,
                            closePrice = cp,
                            positionSize = ps,
                            fee = f,
                            strategyTag = strategyTag,
                            mistakeTag = mistakeTag,
                            notes = notes
                        )
                    )
                }
            ) {
                Text("保存")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("取消") }
        }
    )
}
