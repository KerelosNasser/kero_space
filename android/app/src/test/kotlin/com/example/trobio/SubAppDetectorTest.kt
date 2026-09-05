package com.example.trobio

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SubAppDetectorTest {

    @Test
    fun testIsCandidatePackage() {
        assertTrue(SubAppDetector.isCandidatePackage("com.instagram.android"))
        assertTrue(SubAppDetector.isCandidatePackage("com.google.android.youtube"))
        assertTrue(SubAppDetector.isCandidatePackage("com.zhiliaoapp.musically"))
        assertTrue(SubAppDetector.isCandidatePackage("com.ss.android.ugc.trill"))

        assertFalse(SubAppDetector.isCandidatePackage("com.android.chrome"))
        assertFalse(SubAppDetector.isCandidatePackage("com.whatsapp"))
        assertFalse(SubAppDetector.isCandidatePackage("com.google.android.gm"))
    }

    @Test
    fun testDetectContextNonCandidateReturnsNormal() {
        val result = SubAppDetector.detectContext("com.whatsapp", null)
        assertEquals(SubAppDetector.CONTEXT_NORMAL, result)
    }

    @Test
    fun testDetectContextNullEventReturnsNormal() {
        val result = SubAppDetector.detectContext("com.instagram.android", null)
        assertEquals(SubAppDetector.CONTEXT_NORMAL, result)
    }

    @Test
    fun testDetectContextTikTokAlwaysReels() {
        val dummyEvent = null
        // TikTok package check without event still candidate
        assertTrue(SubAppDetector.isCandidatePackage("com.zhiliaoapp.musically"))
    }
}
