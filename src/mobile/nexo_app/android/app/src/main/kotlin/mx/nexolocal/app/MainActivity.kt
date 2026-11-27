package mx.nexolocal.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.graphics.BitmapFactory
import androidx.core.app.Person
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import java.io.File
import java.util.UUID
import android.media.MediaPlayer
import android.media.MediaDataSource
import io.flutter.plugin.common.MethodChannel.Result

class MainActivity : FlutterActivity() {
    private var appLinks: MethodChannel? = null
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.dataString?.takeIf { it.startsWith("nexolocal://") }?.let { appLinks?.invokeMethod("open", it) }
    }
    private var privateSource: MediaDataSource? = null
    private var privatePlayer: MediaPlayer? = null
    private var privatePlaybackResult: Result? = null
    private var privatePlaybackId: String? = null
    private fun stopPrivateAudio() {
        privatePlayer?.release()
        privatePlayer = null
        privatePlaybackId = null
        privateSource?.close()
        privateSource = null
        privatePlaybackResult?.success(null)
        privatePlaybackResult = null
    }
    override fun onPause() { stopPrivateAudio(); super.onPause() }
    override fun onDestroy() { stopPrivateAudio(); super.onDestroy() }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        appLinks = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mx.nexolocal/links")
        appLinks?.setMethodCallHandler { call, result ->
            if (call.method == "initial") result.success(intent.dataString?.takeIf { it.startsWith("nexolocal://") }) else result.notImplemented()
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mx.nexolocal/share").setMethodCallHandler { call, result ->
            if (call.method != "share") result.notImplemented()
            else {
                val text = call.argument<String>("text")
                if (text == null || !text.startsWith("nexolocal://")) result.error("INVALID_LINK", "Enlace invalido", null)
                else {
                    startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text), call.argument<String>("title") ?: "Nexo Local"))
                    result.success(null)
                }
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mx.nexolocal/chat-notifications")
            .setMethodCallHandler { call, result ->
                try {
                    if (call.method == "clear") {
                        ShortcutManagerCompat.removeAllDynamicShortcuts(this)
                        result.success(null)
                    } else if (call.method == "shortcut") {
                        val id = call.argument<String>("id") ?: throw IllegalArgumentException()
                        val name = call.argument<String>("name") ?: "Nexo Local"
                        val link = call.argument<String>("link") ?: throw IllegalArgumentException()
                        val uri = Uri.parse(link)
                        if (uri.scheme != "nexolocal" || uri.host != "chat") throw IllegalArgumentException()
                        val bytes = call.argument<ByteArray>("avatar")
                        val bitmap = bytes?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
                        val icon = bitmap?.let { IconCompat.createWithBitmap(it) }
                            ?: IconCompat.createWithResource(this, mx.nexolocal.app.R.mipmap.ic_launcher)
                        val person = Person.Builder().setName(name).setKey(id).setIcon(icon).build()
                        val shortcut = ShortcutInfoCompat.Builder(this, id)
                            .setShortLabel(name.take(80)).setLongLived(true).setPerson(person).setIcon(icon)
                            .setIntent(Intent(Intent.ACTION_VIEW, uri, this, MainActivity::class.java))
                            .build()
                        val existing = ShortcutManagerCompat.getDynamicShortcuts(this).any { it.id == id }
                        val updated = if (existing) ShortcutManagerCompat.updateShortcuts(this, listOf(shortcut))
                            else ShortcutManagerCompat.pushDynamicShortcut(this, shortcut)
                        if (!updated) throw IllegalStateException("Shortcut update deferred")
                        result.success(null)
                    } else result.notImplemented()
                } catch (_: Exception) { result.error("SHORTCUT_UNAVAILABLE", "Shortcut unavailable", null) }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mx.nexolocal/private-audio")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "stop" -> {
                        val id = call.arguments as? String
                        if (id == null || id == privatePlaybackId) stopPrivateAudio()
                        result.success(null)
                    }
                    "pause" -> { if (call.arguments == privatePlaybackId) privatePlayer?.pause(); result.success(null) }
                    "resume" -> { if (call.arguments == privatePlaybackId) { privatePlayer?.start(); result.success(null) } else result.error("AUDIO_CHANGED", "Otra nota esta activa", null) }
                    "position" -> {
                        try { result.success(mapOf("id" to privatePlaybackId, "position" to (privatePlayer?.currentPosition ?: 0), "duration" to (privatePlayer?.duration ?: 0), "playing" to (privatePlayer?.isPlaying ?: false))) }
                        catch (_: Exception) { result.success(mapOf("playing" to false)) }
                    }
                    "seek" -> { if (call.argument<String>("id") == privatePlaybackId) privatePlayer?.seekTo((call.argument<Int>("position") ?: 0).coerceAtLeast(0)); result.success(null) }
                    "play" -> {
                        stopPrivateAudio()
                        val bytes = (call.arguments as? ByteArray) ?: call.argument<ByteArray>("bytes")
                        val playbackId = if (call.arguments is Map<*, *>) call.argument<String>("id") else "preview"
                        if (bytes == null || bytes.size < 44 || android.os.Build.VERSION.SDK_INT < 23) {
                            result.error("AUDIO_INVALID", "Audio no compatible", null)
                        } else {
                            val source = object : MediaDataSource() {
                                override fun getSize(): Long = bytes.size.toLong()
                                override fun readAt(position: Long, buffer: ByteArray, offset: Int, size: Int): Int {
                                    if (position < 0 || position >= bytes.size) return -1
                                    val count = minOf(size, bytes.size - position.toInt())
                                    System.arraycopy(bytes, position.toInt(), buffer, offset, count)
                                    return count
                                }
                                override fun close() { bytes.fill(0) }
                            }
                            privateSource = source
                            val player = MediaPlayer()
                            privatePlayer = player
                            privatePlaybackResult = result
                            privatePlaybackId = playbackId
                            try {
                                player.setDataSource(source)
                                player.setOnPreparedListener {
                                    it.start()
                                    privatePlaybackResult?.success(null)
                                    privatePlaybackResult = null
                                }
                                player.setOnCompletionListener { stopPrivateAudio(); source.close() }
                                player.setOnErrorListener { _, _, _ ->
                                    privatePlaybackResult?.error("AUDIO_FAILED", "No se pudo reproducir", null)
                                    privatePlaybackResult = null
                                    stopPrivateAudio(); source.close(); true
                                }
                                player.prepareAsync()
                            } catch (_: Exception) {
                                privatePlaybackResult = null
                                stopPrivateAudio(); source.close()
                                result.error("AUDIO_FAILED", "No se pudo reproducir", null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mx.nexolocal/chat-vault")
            .setMethodCallHandler { call, result ->
                if (call.method != "installationMarker") {
                    result.notImplemented()
                } else {
                    try {
                        val file = File(noBackupFilesDir, "chat-installation-v1")
                        if (!file.exists()) {
                            val bytes = UUID.randomUUID().toString().toByteArray(Charsets.UTF_8)
                            java.io.FileOutputStream(file).use { output ->
                                output.write(bytes)
                                output.fd.sync()
                            }
                        }
                        val marker = file.readText(Charsets.UTF_8)
                        UUID.fromString(marker)
                        result.success(marker)
                    } catch (_: Exception) {
                        result.error("CHAT_STORAGE_UNAVAILABLE", "Almacenamiento seguro no disponible", null)
                    }
                }
            }
    }
}
