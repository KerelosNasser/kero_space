package com.example.trobio

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class OverlayManagerLogicTest {

    @Test
    fun testFormatDurationSeconds() {
        assertEquals("00:30", OverlayManager.formatDuration(30_000L))
        assertEquals("00:05", OverlayManager.formatDuration(5_000L))
        assertEquals("01:00", OverlayManager.formatDuration(60_000L))
    }

    @Test
    fun testFormatDurationMinutes() {
        assertEquals("05:30", OverlayManager.formatDuration(330_000L))
        assertEquals("15:00", OverlayManager.formatDuration(900_000L))
        assertEquals("59:59", OverlayManager.formatDuration(3_599_000L))
    }

    @Test
    fun testFormatDurationHours() {
        assertEquals("01:00:00", OverlayManager.formatDuration(3_600_000L))
        assertEquals("02:15:30", OverlayManager.formatDuration(8_130_000L))
    }

    @Test
    fun testHasBreakBeenTakenRecentlyDefaultFalse() {
        assertFalse(OverlayManager.hasBreakBeenTakenRecently("com.unseen.app"))
    }
}
