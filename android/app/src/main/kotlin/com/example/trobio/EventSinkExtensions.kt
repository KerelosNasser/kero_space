package com.example.trobio

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel

private const val TAG = "EventSinkHelper"
private val mainHandler by lazy { Handler(Looper.getMainLooper()) }

/**
 * Safely delivers an event to Flutter's [EventChannel.EventSink] on the Main UI thread.
 *
 * Catches any [IllegalStateException], [AssertionError], or engine-detached exceptions
 * to prevent tearing down the native Android process if Flutter isolates hot-restart or disconnect.
 */
fun EventChannel.EventSink?.safeSuccess(event: Any?) {
    val sink = this ?: return
    if (Looper.myLooper() == Looper.getMainLooper()) {
        try {
            sink.success(event)
        } catch (e: Throwable) {
            Log.w(TAG, "Failed to emit event directly on main thread: ${e.message}")
        }
    } else {
        mainHandler.post {
            try {
                sink.success(event)
            } catch (e: Throwable) {
                Log.w(TAG, "Failed to emit event posted to main thread: ${e.message}")
            }
        }
    }
}

/**
 * Safely delivers an error to Flutter's [EventChannel.EventSink] on the Main UI thread.
 */
fun EventChannel.EventSink?.safeError(errorCode: String, errorMessage: String?, errorDetails: Any?) {
    val sink = this ?: return
    if (Looper.myLooper() == Looper.getMainLooper()) {
        try {
            sink.error(errorCode, errorMessage, errorDetails)
        } catch (e: Throwable) {
            Log.w(TAG, "Failed to emit error directly on main thread: ${e.message}")
        }
    } else {
        mainHandler.post {
            try {
                sink.error(errorCode, errorMessage, errorDetails)
            } catch (e: Throwable) {
                Log.w(TAG, "Failed to emit error posted to main thread: ${e.message}")
            }
        }
    }
}
