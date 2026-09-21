package dev.karan.spidertracker

import android.media.AudioAttributes
import android.media.SoundPool
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts a tiny sound-effect channel. SoundPool gives the low latency a
 * tap-triggered effect needs, with no plugin dependency; the clips are
 * short WAVs in res/raw, referenced directly so resource shrinking keeps
 * them.
 */
class MainActivity : FlutterActivity() {
    private var pool: SoundPool? = null
    private val ids = mutableMapOf<String, Int>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val p = SoundPool.Builder().setMaxStreams(4).setAudioAttributes(attrs).build()
        pool = p
        ids["thwip"] = p.load(this, R.raw.sfx_thwip, 1)
        ids["levelup"] = p.load(this, R.raw.sfx_levelup, 1)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "spidertracker/sfx")
            .setMethodCallHandler { call, result ->
                if (call.method == "play") {
                    ids[call.argument<String>("name")]?.let { p.play(it, 1f, 1f, 1, 0, 1f) }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        pool?.release()
        pool = null
        super.onDestroy()
    }
}
