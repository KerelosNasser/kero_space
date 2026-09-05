package com.example.trobio

import android.os.Build
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

object SubAppDetector {

    const val CONTEXT_NORMAL = "normal"
    const val CONTEXT_REELS = "reels"
    const val CONTEXT_SHORTS = "shorts"

    /**
     * Fast O(1) check whether the package supports sub-app detection.
     * Prevents inspect overhead on 99% of Android applications.
     */
    fun isCandidatePackage(packageName: String): Boolean {
        return packageName == "com.instagram.android" ||
                packageName == "com.google.android.youtube" ||
                packageName == "com.zhiliaoapp.musically" ||
                packageName == "com.ss.android.ugc.trill"
    }

    /**
     * Determines the sub-app context based on the accessibility event and the package name.
     */
    fun detectContext(packageName: String, event: AccessibilityEvent?): String {
        if (event == null || !isCandidatePackage(packageName)) return CONTEXT_NORMAL

        // Heuristics for Instagram Reels
        if (packageName == "com.instagram.android") {
            val text = event.text.joinToString(" ").lowercase()
            val desc = event.contentDescription?.toString()?.lowercase() ?: ""
            
            if (desc.contains("reels") || text.contains("reels") || text.contains("clips")) {
                return CONTEXT_REELS
            }
            
            var node: AccessibilityNodeInfo? = null
            try {
                node = event.source
                if (node != null && checkNodeForReels(node)) {
                    return CONTEXT_REELS
                }
            } finally {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    try {
                        @Suppress("DEPRECATION")
                        node?.recycle()
                    } catch (_: Exception) {}
                }
            }
        }

        // Heuristics for YouTube Shorts
        if (packageName == "com.google.android.youtube") {
            val text = event.text.joinToString(" ").lowercase()
            val desc = event.contentDescription?.toString()?.lowercase() ?: ""
            if (desc.contains("shorts") || text.contains("shorts")) {
                return CONTEXT_SHORTS
            }
        }
        
        // TikTok is entirely reels
        if (packageName == "com.zhiliaoapp.musically" || packageName == "com.ss.android.ugc.trill") {
            return CONTEXT_REELS
        }

        return CONTEXT_NORMAL
    }

    private fun checkNodeForReels(node: AccessibilityNodeInfo): Boolean {
        val viewId = node.viewIdResourceName ?: ""
        return viewId.contains("reel", ignoreCase = true) || viewId.contains("clips", ignoreCase = true)
    }
}
