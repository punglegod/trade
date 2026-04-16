package com.punglegod.trade.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val LightColors = lightColorScheme(
    primary = PrimaryBlue,
    onPrimary = androidx.compose.ui.graphics.Color.White,
    background = BackgroundTop,
    onBackground = TextPrimary,
    surface = GlassTint,
    onSurface = TextPrimary
)

private val DarkColors = darkColorScheme(
    primary = PrimaryBlue,
    onPrimary = androidx.compose.ui.graphics.Color.White
)

@Composable
fun TradeTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = LightColors,
        typography = Typography,
        content = content
    )
}
