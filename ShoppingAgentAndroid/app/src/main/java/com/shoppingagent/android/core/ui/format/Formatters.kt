package com.shoppingagent.android.core.ui.format

import java.text.NumberFormat
import java.util.Locale

private val idrFormat: NumberFormat =
    NumberFormat.getCurrencyInstance(Locale.forLanguageTag("id-ID")).apply {
        maximumFractionDigits = 0
    }

/** 14999000 -> "Rp14.999.000" */
fun Long.toIdrString(): String = idrFormat.format(this)

fun Long?.toIdrStringOrEmpty(): String = this?.toIdrString().orEmpty()

/** 4.78 -> "4.8" */
fun Double.toRatingString(): String = String.format(Locale.US, "%.1f", this)

/** 1248 -> "1.2 rb" */
fun Int.toCompactCountString(): String =
    if (this >= 1_000) String.format(Locale.US, "%.1f rb", this / 1_000.0) else this.toString()

/** Menyisakan digit saja, dipakai input harga. */
fun String.digitsOnly(): String = filter { it.isDigit() }
