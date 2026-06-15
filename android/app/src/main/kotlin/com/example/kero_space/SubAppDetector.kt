package com.example.kero_space

import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

object SubAppDetector {

    const val CONTEXT_NORMAL = "normal"
    const val CONTEXT_REELS = "reels"
    const val CONTEXT_SHORTS = "shorts"

    /**
     * Determines the sub-app context based on the accessibility event and the package name.
     */
    fun detectContext(packageName: String, event: AccessibilityEvent?): String {
        if (event == null) return CONTEXT_NORMAL

        // Heuristics for Instagram Reels
        if (packageName == "com.instagram.android") {
            val text = event.text?.joinToString(" ")?.lowercase() ?: ""
            val desc = event.contentDescription?.toString()?.lowercase() ?: ""
            
            if (desc.contains("reels") || text.contains("reels") || text.contains("clips")) {
                return CONTEXT_REELS
            }
            
            val node = event.source
            if (node != null && checkNodeForReels(node)) {
                return CONTEXT_REELS
            }
        }

        // Heuristics for YouTube Shorts
        if (packageName == "com.google.android.youtube") {
            val text = event.text?.joinToString(" ")?.lowercase() ?: ""
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
        if (viewId.contains("reel", ignoreCase = true) || viewId.contains("clips", ignoreCase = true)) {
            return true
        }
        return false
    }
}
