package com.punglegod.trade

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.punglegod.trade.data.FileTradeStore
import com.punglegod.trade.data.TradeRepository
import kotlinx.coroutines.launch

enum class AppTab(val title: String) {
    RECORDS("记录"),
    STATS("统计"),
    REPORT("周报")
}

class MainViewModel(application: Application) : AndroidViewModel(application) {
    val repository = TradeRepository(FileTradeStore(application.applicationContext))

    var currentTab by mutableStateOf(AppTab.RECORDS)
        private set

    init {
        viewModelScope.launch {
            repository.bootstrap()
        }
    }

    fun switchTab(tab: AppTab) {
        currentTab = tab
    }
}
