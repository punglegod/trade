package com.punglegod.trade.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.punglegod.trade.ui.theme.GlassBorder
import com.punglegod.trade.ui.theme.GlassTint
import com.punglegod.trade.ui.theme.PrimaryBlue
import com.punglegod.trade.ui.theme.PrimaryBlueDark
import com.punglegod.trade.ui.theme.TextPrimary
import com.punglegod.trade.ui.theme.TextSecondary

@Composable
fun PillPrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(100.dp))
            .background(
                brush = Brush.horizontalGradient(
                    colors = listOf(PrimaryBlue, PrimaryBlueDark)
                )
            )
            .clickable(onClick = onClick)
            .padding(horizontal = 18.dp, vertical = 12.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(text = text, color = Color.White, style = MaterialTheme.typography.labelLarge)
    }
}

@Composable
fun FilterChip(
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val bg = if (selected) PrimaryBlue.copy(alpha = 0.18f) else Color.White.copy(alpha = 0.55f)
    val border = if (selected) PrimaryBlue.copy(alpha = 0.35f) else Color.White.copy(alpha = 0.75f)
    val textColor = if (selected) PrimaryBlueDark else TextSecondary

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(100.dp))
            .background(bg)
            .border(1.dp, border, RoundedCornerShape(100.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp)
    ) {
        Text(text = label, color = textColor, style = MaterialTheme.typography.labelMedium)
    }
}

@Composable
fun GlassCard(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(containerColor = Color.Transparent),
        shape = RoundedCornerShape(24.dp)
    ) {
        Box(
            modifier = Modifier
                .background(
                    Brush.linearGradient(
                        colors = listOf(
                            GlassTint,
                            Color.White.copy(alpha = 0.14f)
                        )
                    )
                )
                .border(1.dp, GlassBorder, RoundedCornerShape(24.dp))
                .padding(16.dp)
        ) {
            content()
        }
    }
}

@Composable
fun <T> PillSegmentedControl(
    items: List<T>,
    selected: T,
    label: (T) -> String,
    onSelect: (T) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(100.dp))
            .background(Color.White.copy(alpha = 0.45f))
            .padding(4.dp)
            .fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        items.forEach { item ->
            val isSelected = item == selected
            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(100.dp))
                    .background(if (isSelected) PrimaryBlue.copy(alpha = 0.2f) else Color.Transparent)
                    .clickable { onSelect(item) }
                    .padding(vertical = 8.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = label(item),
                    color = if (isSelected) TextPrimary else TextSecondary,
                    style = MaterialTheme.typography.labelMedium
                )
            }
        }
    }
}
