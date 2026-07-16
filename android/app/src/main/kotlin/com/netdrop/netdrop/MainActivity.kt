package com.qayham.netdrop

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.net.URLConnection

class MainActivity : FlutterActivity() {
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

    /**
     * MediaStore only allows certain top-level folders per collection.
     * Images → Pictures/DCIM, video → Movies, audio → Music, everything else → Download.
     */
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
