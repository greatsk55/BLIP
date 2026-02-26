package com.bakkum.blip

import android.app.Activity
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val screenshotChannel = "com.bakkum.blip/screenshot"
    private val audioChannel = "com.bakkum.blip/audio"
    private var screenshotMethodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 스크린샷 감지 채널
        screenshotMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, screenshotChannel
        )

        // 시스템 사운드 채널 (WebRTC와 독립적인 STREAM_NOTIFICATION)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, audioChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "playBeep") {
                    try {
                        val toneGen = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 80)
                        toneGen.startTone(ToneGenerator.TONE_PROP_BEEP, 150)
                        // 재생 후 해제 (150ms 후)
                        android.os.Handler(mainLooper).postDelayed({ toneGen.release() }, 200)
                        result.success(null)
                    } catch (e: Exception) {
                        result.success(null) // 실패해도 크래시 방지
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Android 14+ (API 34): ScreenCaptureCallback으로 스크린샷 감지
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            try {
                registerScreenCaptureCallback(mainExecutor, object : Activity.ScreenCaptureCallback {
                    override fun onScreenCaptured() {
                        screenshotMethodChannel?.invokeMethod("onScreenshot", null)
                    }
                })
            } catch (e: Exception) {
                // 권한 없거나 에뮬레이터 등에서 실패 시 무시
                android.util.Log.w("MainActivity", "ScreenCaptureCallback registration failed", e)
            }
        }
    }
}
