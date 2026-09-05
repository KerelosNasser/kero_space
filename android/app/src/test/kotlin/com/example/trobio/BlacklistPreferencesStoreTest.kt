package com.example.trobio

import com.example.trobio.telemetry.AllowedWindow
import com.example.trobio.telemetry.BlacklistPreferencesStore
import com.example.trobio.telemetry.ParsedRule
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class BlacklistPreferencesStoreTest {

    @Test
    fun testAllowedWindowContainsHour() {
        val window = AllowedWindow(startHour = 9, endHour = 17)
        assertTrue(window.containsHour(9))
        assertTrue(window.containsHour(12))
        assertTrue(window.containsHour(16))
        assertFalse(window.containsHour(8))
        assertFalse(window.containsHour(17))
        assertFalse(window.containsHour(22))
    }

    @Test
    fun testParsedRuleIsAllowedAt() {
        val rule = ParsedRule(
            packageName = "com.instagram.android",
            allowedWindows = listOf(AllowedWindow(12, 14), AllowedWindow(18, 20)),
        )

        assertTrue(rule.isAllowedAt(12))
        assertTrue(rule.isAllowedAt(13))
        assertFalse(rule.isAllowedAt(14))
        assertTrue(rule.isAllowedAt(19))
        assertFalse(rule.isAllowedAt(10))
    }

    @Test
    fun testParseJsonToRulesMap() {
        val json = """
            [
                {
                    "packageName": "com.instagram.android",
                    "decisionBreakSeconds": 45,
                    "sessionLimitMinutes": 15,
                    "cooldownMinutes": 30,
                    "subAppTarget": "reels",
                    "allowedWindows": [
                        {"startHour": 12, "endHour": 13}
                    ]
                },
                {
                    "packageName": "com.twitter.android",
                    "decisionBreakSeconds": 20
                }
            ]
        """.trimIndent()

        val rulesMap = BlacklistPreferencesStore.parseJsonToRulesMap(json)
        assertEquals(2, rulesMap.size)

        val instaRule = rulesMap["com.instagram.android"]
        assertNotNull(instaRule)
        assertEquals("com.instagram.android", instaRule?.packageName)
        assertEquals(45, instaRule?.decisionBreakSeconds)
        assertEquals(15, instaRule?.sessionLimitMinutes)
        assertEquals(30, instaRule?.cooldownMinutes)
        assertEquals("reels", instaRule?.subAppTarget)
        assertEquals(1, instaRule?.allowedWindows?.size)
        assertTrue(instaRule?.isAllowedAt(12) == true)
        assertFalse(instaRule?.isAllowedAt(15) == true)

        val twitterRule = rulesMap["com.twitter.android"]
        assertNotNull(twitterRule)
        assertEquals(20, twitterRule?.decisionBreakSeconds)
        assertNull(twitterRule?.sessionLimitMinutes)
        assertNull(twitterRule?.cooldownMinutes)
        assertNull(twitterRule?.subAppTarget)
    }

    @Test
    fun testParseInvalidJsonReturnsEmptyMap() {
        val rulesMap = BlacklistPreferencesStore.parseJsonToRulesMap("not a json")
        assertTrue(rulesMap.isEmpty())
    }
}
