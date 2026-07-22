package com.example.rec_quiz

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AUDIO_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "playCorrectAnswer" -> playTone(ToneGenerator.TONE_PROP_ACK, result)
                "playIncorrectAnswer" -> playTone(ToneGenerator.TONE_PROP_NACK, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun playTone(tone: Int, result: MethodChannel.Result) {
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val notificationsAreAudible =
                audioManager.ringerMode == AudioManager.RINGER_MODE_NORMAL &&
                    audioManager.getStreamVolume(AudioManager.STREAM_NOTIFICATION) > 0

            if (!notificationsAreAudible) {
                result.success(null)
                return
            }

            val generator = ToneGenerator(AudioManager.STREAM_NOTIFICATION, TONE_VOLUME)
            generator.startTone(tone, TONE_DURATION_MILLISECONDS)
            Handler(Looper.getMainLooper()).postDelayed(
                { generator.release() },
                TONE_DURATION_MILLISECONDS.toLong(),
            )
            result.success(null)
        } catch (error: RuntimeException) {
            result.error("audio_unavailable", "Unable to play quiz feedback.", null)
        }
    }

    companion object {
        private const val AUDIO_CHANNEL = "rec_quiz/audio_feedback"
        private const val TONE_VOLUME = 70
        private const val TONE_DURATION_MILLISECONDS = 180
    }
}
