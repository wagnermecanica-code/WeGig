package com.wegig.wegig

import android.util.Log
import com.tiktok.TikTokBusinessSdk
import io.flutter.app.FlutterApplication

class WeGigApplication : FlutterApplication() {

    override fun onCreate() {
        super.onCreate()
        initTikTokSdk()
    }

    private fun initTikTokSdk() {
        try {
            val config = TikTokBusinessSdk.TTConfig(this)
                .setAppId("7597471410646286354")

            TikTokBusinessSdk.initializeSdk(config)
            Log.d("WeGigApp", "✅ TikTok Business SDK initialized")
        } catch (e: Exception) {
            Log.e("WeGigApp", "⚠️ TikTok SDK init failed: ${e.message}", e)
        }
    }
}
