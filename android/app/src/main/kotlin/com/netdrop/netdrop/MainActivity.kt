package com.qayham.netdrop

import android.content.ContentValues
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.URLConnection

class MainActivity : FlutterActivity() {
    private var shareChannel: MethodChannel? = null
    private var pendingSharePayload: ArrayList<HashMap<String, Any?>>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.qayham.netdrop/receive",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToNetDrop" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                        result.error(
                            "UNSUPPORTED",
                            "MediaStore save requires Android 10 or higher",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    val filePath = call.argument<String>("filePath")
                    val fileName = call.argument<String>("fileName")
                    val subfolder = call.argument<String>("subfolder") ?: "other"
                    val mimeType = call.argument<String>("mimeType")
                        ?: URLConnection.guessContentTypeFromName(fileName)
                        ?: "application/octet-stream"
                    if (filePath == null || fileName == null) {
                        result.error("INVALID_ARGS", "filePath and fileName are required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val uri = saveToNetDrop(filePath, fileName, subfolder, mimeType)
                        result.success(uri.toString())
                    } catch (error: Exception) {
                        result.error("SAVE_ERROR", error.message, null)
                    }
                }

                "openFile" -> {
                    val uriValue = call.argument<String>("uri")
                    val mimeType = call.argument<String>("mimeType") ?: "*/*"
                    if (uriValue == null) {
                        result.error("INVALID_ARGS", "uri is required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        openFile(uriValue, mimeType)
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("OPEN_ERROR", error.message, null)
                    }
                }

                "getDeviceName" -> {
                    try {
                        result.success(readDeviceName())
                    } catch (error: Exception) {
                        result.error("DEVICE_NAME_ERROR", error.message, null)
                    }
                }

                "restartApp" -> {
                    try {
                        restartApp()
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("RESTART_ERROR", error.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        shareChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.qayham.netdrop/share",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialShare" -> {
                        val payload = pendingSharePayload
                        pendingSharePayload = null
                        result.success(payload)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        deliverPendingShare()
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        handleShareIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleShareIntent(intent)
    }

    private fun handleShareIntent(intent: Intent?) {
        if (intent == null) {
            return
        }

        val action = intent.action ?: return
        val uris = when (action) {
            Intent.ACTION_SEND -> {
                val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                if (uri != null) listOf(uri) else emptyList()
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM) ?: emptyList()
            }
            else -> emptyList()
        }

        if (uris.isEmpty()) {
            return
        }

        val payload = ArrayList<HashMap<String, Any?>>()
        for (uri in uris) {
            val copied = copyUriToCache(uri) ?: continue
            payload.add(copied)
        }

        if (payload.isEmpty()) {
            return
        }

        pendingSharePayload = payload
        deliverPendingShare()
        setIntent(Intent(Intent.ACTION_MAIN))
    }

    private fun deliverPendingShare() {
        val channel = shareChannel ?: return
        val payload = pendingSharePayload ?: return
        pendingSharePayload = null
        channel.invokeMethod("onShare", payload)
    }

    private fun copyUriToCache(uri: Uri): HashMap<String, Any?>? {
        val resolver = contentResolver
        var displayName = "shared_file"
        var size = 0L
        var mimeType = resolver.getType(uri)

        resolver.query(uri, null, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                displayName = cursor.readString(OpenableColumns.DISPLAY_NAME) ?: displayName
                size = cursor.readLong(OpenableColumns.SIZE)
            }
        }

        if (mimeType.isNullOrEmpty()) {
            mimeType = URLConnection.guessContentTypeFromName(displayName)
                ?: "application/octet-stream"
        }

        val cacheDir = File(cacheDir, "shared_intake")
        if (!cacheDir.exists()) {
            cacheDir.mkdirs()
        }

        val safeName = displayName.replace(Regex("""[\\/:*?"<>|]"""), "_")
        val dest = File(cacheDir, "${System.currentTimeMillis()}_$safeName")

        return try {
            resolver.openInputStream(uri)?.use { input ->
                FileOutputStream(dest).use { output ->
                    input.copyTo(output)
                }
            } ?: return null

            hashMapOf(
                "path" to dest.absolutePath,
                "name" to displayName,
                "mimeType" to mimeType,
                "size" to if (size > 0) size else dest.length(),
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun Cursor.readString(column: String): String? {
        val index = getColumnIndex(column)
        if (index < 0 || isNull(index)) {
            return null
        }
        return getString(index)
    }

    private fun Cursor.readLong(column: String): Long {
        val index = getColumnIndex(column)
        if (index < 0 || isNull(index)) {
            return 0L
        }
        return getLong(index)
    }

    private fun saveToNetDrop(
        filePath: String,
        fileName: String,
        subfolder: String,
        mimeType: String,
    ): Uri {
        val collection = mediaCollectionFor(mimeType)
        val relativePath = relativePathFor(mimeType, subfolder)

        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
        }

        val resolver = contentResolver
        val uri = resolver.insert(collection, contentValues)
            ?: throw IllegalStateException("Failed to create download entry")

        FileInputStream(filePath).use { input ->
            resolver.openOutputStream(uri)?.use { output ->
                input.copyTo(output)
            } ?: throw IllegalStateException("Failed to open output stream")
        }

        return uri
    }

    private fun mediaCollectionFor(mimeType: String): Uri = when {
        mimeType.startsWith("image/") -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        mimeType.startsWith("video/") -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        mimeType.startsWith("audio/") -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        else -> MediaStore.Downloads.EXTERNAL_CONTENT_URI
    }

    private fun relativePathFor(mimeType: String, subfolder: String): String {
        val baseDir = when {
            mimeType.startsWith("image/") -> Environment.DIRECTORY_PICTURES
            mimeType.startsWith("video/") -> Environment.DIRECTORY_MOVIES
            mimeType.startsWith("audio/") -> Environment.DIRECTORY_MUSIC
            else -> Environment.DIRECTORY_DOWNLOADS
        }
        return "$baseDir/NetDrop"
    }

    private fun restartApp() {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        intent?.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        Runtime.getRuntime().exit(0)
    }

    private fun openFile(uriValue: String, mimeType: String) {
        val uri = if (uriValue.startsWith("content://")) {
            Uri.parse(uriValue)
        } else {
            val file = File(uriValue)
            FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file,
            )
        }

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        startActivity(Intent.createChooser(intent, "Open with"))
    }

    private fun readDeviceName(): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            Settings.Global.getString(contentResolver, Settings.Global.DEVICE_NAME)
                ?.trim()
                ?.takeIf { it.isNotEmpty() }
                ?.let { return it }
        }

        Settings.Secure.getString(contentResolver, "bluetooth_name")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?.let { return it }

        return Build.MODEL?.trim()?.takeIf { it.isNotEmpty() } ?: "Android device"
    }
}
