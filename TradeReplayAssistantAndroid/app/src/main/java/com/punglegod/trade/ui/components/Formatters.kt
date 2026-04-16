package com.punglegod.trade.ui.components

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

private val dateTimeFormat = SimpleDateFormat("MM-dd HH:mm", Locale.CHINA)
private val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.CHINA)

fun Long.formatDateTime(): String = dateTimeFormat.format(Date(this))
fun Long.formatDateOnly(): String = dateFormat.format(Date(this))
fun Double.format2(): String = String.format(Locale.CHINA, "%.2f", this)
fun Double.formatPct(): String = String.format(Locale.CHINA, "%.1f%%", this * 100)
