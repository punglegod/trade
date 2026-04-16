package com.punglegod.trade

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.punglegod.trade.ui.components.FilterChip
import com.punglegod.trade.ui.screens.RecordsScreen
import com.punglegod.trade.ui.screens.ReportScreen
import com.punglegod.trade.ui.screens.StatsScreen
import com.punglegod.trade.ui.theme.BackgroundBottom
import com.punglegod.trade.ui.theme.BackgroundTop
import com.punglegod.trade.ui.theme.TradeTheme

class MainActivity : ComponentActivity() {
    private val vm: MainViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            TradeTheme {
                AppRoot(vm)
            }
        }
    }
}

@Composable
private fun AppRoot(vm: MainViewModel) {
    Scaffold(
        containerColor = Color.Transparent,
        bottomBar = {
            BottomNav(vm)
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(BackgroundTop, BackgroundBottom)
                    )
                )
                .padding(padding)
        ) {
            when (vm.currentTab) {
                AppTab.RECORDS -> RecordsScreen(vm.repository)
                AppTab.STATS -> StatsScreen(vm.repository)
                AppTab.REPORT -> ReportScreen(vm.repository)
            }
        }
    }
}

@Composable
private fun BottomNav(vm: MainViewModel) {
    val tabs = AppTab.entries
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp)
            .clip(RoundedCornerShape(100.dp))
            .background(Color.White.copy(alpha = 0.6f))
            .padding(8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        tabs.forEach { tab ->
            val selected = tab == vm.currentTab
            FilterChip(
                label = tab.title,
                selected = selected,
                onClick = { vm.switchTab(tab) },
                modifier = Modifier.weight(1f)
            )
        }
    }
}
