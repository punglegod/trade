package com.punglegod.trade.data

import android.content.Context
import com.punglegod.trade.domain.TradeSnapshot
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File

interface TradeStore {
    suspend fun load(): List<TradeSnapshot>
    suspend fun save(trades: List<TradeSnapshot>)
}

class FileTradeStore(
    context: Context,
    private val fileName: String = "trades.json"
) : TradeStore {
    private val json = Json { ignoreUnknownKeys = true; prettyPrint = false }
    private val file = File(context.filesDir, fileName)

    override suspend fun load(): List<TradeSnapshot> = withContext(Dispatchers.IO) {
        if (!file.exists()) {
            return@withContext emptyList()
        }
        val content = file.readText()
        if (content.isBlank()) {
            return@withContext emptyList()
        }
        runCatching { json.decodeFromString<List<TradeSnapshot>>(content) }
            .getOrElse { emptyList() }
    }

    override suspend fun save(trades: List<TradeSnapshot>) = withContext(Dispatchers.IO) {
        val parent = file.parentFile
        if (parent != null && !parent.exists()) {
            parent.mkdirs()
        }
        file.writeText(json.encodeToString(trades))
    }
}

class InMemoryTradeStore(seed: List<TradeSnapshot> = emptyList()) : TradeStore {
    private var cache: List<TradeSnapshot> = seed

    override suspend fun load(): List<TradeSnapshot> = cache

    override suspend fun save(trades: List<TradeSnapshot>) {
        cache = trades
    }
}
