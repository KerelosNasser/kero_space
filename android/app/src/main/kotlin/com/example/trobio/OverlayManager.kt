package com.example.trobio

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.ConcurrentHashMap

/**
 * Manages the decision-break overlay window.
 *
 * All view mutations happen on the main thread via [mainHandler].
 * [overlayShowing] is the single source-of-truth for whether the overlay
 * is currently visible — it is set synchronously before posting to the handler
 * to prevent duplicate showOverlay calls racing through the null-check.
 */
object OverlayManager {

    private const val TAG = "OverlayManager"

    private val mainHandler = Handler(Looper.getMainLooper())
    private var windowManager: WindowManager? = null
    private var overlayView: LinearLayout? = null

    private val overlayShowing = AtomicBoolean(false)
    private val lastBreakTakenMap = ConcurrentHashMap<String, Long>()

    fun hasBreakBeenTakenRecently(packageName: String): Boolean {
        val lastTime = lastBreakTakenMap[packageName] ?: 0L
        return System.currentTimeMillis() - lastTime < 15 * 60 * 1000L
    }

    fun recordBreakTaken(packageName: String) {
        lastBreakTakenMap[packageName] = System.currentTimeMillis()
    }

    fun showOverlay(context: Context, packageName: String, durationSeconds: Int) {
        if (!overlayShowing.compareAndSet(false, true)) {
            Log.d(TAG, "showOverlay called but overlay already showing — ignoring")
            return
        }
        if (durationSeconds <= 0) {
            Log.w(TAG, "showOverlay called with durationSeconds=$durationSeconds — ignoring")
            overlayShowing.set(false)
            return
        }

        mainHandler.post {
            if (overlayView != null) return@post // Already added to WindowManager

            windowManager = context.applicationContext
                .getSystemService(Context.WINDOW_SERVICE) as WindowManager

            val layout = LinearLayout(context.applicationContext).apply {
                orientation = LinearLayout.VERTICAL
                setBackgroundColor(Color.parseColor("#E6000000")) // 90% Black
                gravity = Gravity.CENTER
            }

            layout.addView(TextView(context.applicationContext).apply {
                text = "Decision Break\n$packageName"
                setTextColor(Color.WHITE)
                textSize = 24f
                gravity = Gravity.CENTER
            })

            val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                layoutFlag,
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT,
            )

            try {
                windowManager?.addView(layout, params)
                overlayView = layout
                Log.d(TAG, "Overlay shown for $packageName (${durationSeconds}s)")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to add overlay view", e)
                overlayShowing.set(false)
                return@post
            }

            // Auto-dismiss after duration
            mainHandler.postDelayed({ dismissOverlay(packageName) }, durationSeconds * 1000L)
        }
    }

    fun dismissOverlay(packageName: String? = null) {
        mainHandler.post {
            val view = overlayView ?: run {
                overlayShowing.set(false)
                return@post
            }
            try {
                windowManager?.removeView(view)
                Log.d(TAG, "Overlay dismissed")
                if (packageName != null) {
                    recordBreakTaken(packageName)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to remove overlay view", e)
            } finally {
                overlayView = null
                overlayShowing.set(false)
            }
        }
    }
}

