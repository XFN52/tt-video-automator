package com.example.tt_video_automator

import android.os.Build
import android.os.Handler
import android.os.Looper
import com.example.tt_video_automator.gpu.GpuVideoTranscoder
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.tt_video_automator/gpu_engine"
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var activeTranscoder: GpuVideoTranscoder? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> {
                    // OpenGL ES 3.0 + MediaCodec Surface-to-Surface supported on Android 7.0+ (API 24+)
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.N)
                }
                "renderVideoTask" -> {
                    val inputPath = call.argument<String>("inputPath") ?: ""
                    val outputPath = call.argument<String>("outputPath") ?: ""
                    val outputWidth = call.argument<Int>("outputWidth") ?: 720
                    val outputHeight = call.argument<Int>("outputHeight") ?: 1280
                    val bitrate = call.argument<Int>("bitrate") ?: 2_000_000
                    val startTimeUs = (call.argument<Number>("startTimeUs")?.toLong()) ?: 0L
                    val endTimeUs = (call.argument<Number>("endTimeUs")?.toLong()) ?: Long.MAX_VALUE
                    val brightness = (call.argument<Number>("brightness")?.toFloat()) ?: 0.0f
                    val contrast = (call.argument<Number>("contrast")?.toFloat()) ?: 1.0f
                    val saturation = (call.argument<Number>("saturation")?.toFloat()) ?: 1.0f
                    val noiseLevel = (call.argument<Number>("noiseLevel")?.toFloat()) ?: 0.0f
                    val isMirrored = call.argument<Boolean>("isMirrored") ?: false
                    val bannerPath = call.argument<String>("bannerPath")
                    val bannerXRatio = (call.argument<Number>("bannerXRatio")?.toFloat()) ?: 0.0f
                    val bannerYRatio = (call.argument<Number>("bannerYRatio")?.toFloat()) ?: 0.122f
                    val bannerWidthRatio = (call.argument<Number>("bannerWidthRatio")?.toFloat()) ?: 1.0f
                    val bannerHeightRatio = (call.argument<Number>("bannerHeightRatio")?.toFloat()) ?: 0.161f
                    val subtitles = call.argument<List<Map<String, Any>>>("subtitles")
                    val subtitleYRatio = (call.argument<Number>("subtitleYRatio")?.toFloat()) ?: 0.72f
                    val partNumberText = call.argument<String>("partNumberText")
                    val numberingYRatio = (call.argument<Number>("numberingYRatio")?.toFloat()) ?: 0.033f
                    val textHook = call.argument<String>("textHook")
                    val textHookYRatio = (call.argument<Number>("textHookYRatio")?.toFloat()) ?: 0.08f

                    val transcoder = GpuVideoTranscoder()
                    activeTranscoder = transcoder

                    val cacheDir = applicationContext.cacheDir.absolutePath

                    executor.execute {
                        val success = transcoder.transcode(
                            inputPath = inputPath,
                            outputPath = outputPath,
                            outputWidth = outputWidth,
                            outputHeight = outputHeight,
                            bitrate = bitrate,
                            startTimeUs = startTimeUs,
                            endTimeUs = endTimeUs,
                            brightness = brightness,
                            contrast = contrast,
                            saturation = saturation,
                            noiseLevel = noiseLevel,
                            isMirrored = isMirrored,
                            bannerPath = bannerPath,
                            bannerXRatio = bannerXRatio,
                            bannerYRatio = bannerYRatio,
                            bannerWidthRatio = bannerWidthRatio,
                            bannerHeightRatio = bannerHeightRatio,
                            subtitlesJson = subtitles,
                            subtitleYRatio = subtitleYRatio,
                            partNumberText = partNumberText,
                            numberingYRatio = numberingYRatio,
                            textHook = textHook,
                            textHookYRatio = textHookYRatio,
                            cacheDir = cacheDir,
                            onProgress = { progress ->
                                mainHandler.post {
                                    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                                        .invokeMethod("onProgress", mapOf(
                                            "outputPath" to outputPath,
                                            "progress" to progress
                                        ))
                                }
                            }
                        )

                        mainHandler.post {
                            result.success(mapOf(
                                "success" to success,
                                "outputPath" to outputPath
                            ))
                        }
                    }
                }
                "saveTextFile" -> {
                    val fullPath = call.argument<String>("path")
                    val content = call.argument<String>("content") ?: ""
                    if (fullPath == null) {
                        result.error("INVALID_ARGS", "Path is null", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val file = java.io.File(fullPath)
                        file.parentFile?.mkdirs()

                        var writeSuccess = false
                        try {
                            file.writeText(content, Charsets.UTF_8)
                            writeSuccess = true
                        } catch (e: Exception) {
                            android.util.Log.w("MainActivity", "Direct write failed ($e), using MediaStore insertion...")
                        }

                        if (!writeSuccess && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val fileName = file.name
                            val parentPath = file.parentFile?.absolutePath ?: ""
                            val relativePath = if (parentPath.contains("/storage/emulated/0/")) {
                                parentPath.substringAfter("/storage/emulated/0/").trim('/') + "/"
                            } else {
                                "Movies/TT_Automator/"
                            }

                            val collectionUri = android.provider.MediaStore.Files.getContentUri("external")
                            val selection = "${android.provider.MediaStore.MediaColumns.DISPLAY_NAME} = ? AND ${android.provider.MediaStore.MediaColumns.RELATIVE_PATH} = ?"
                            val selectionArgs = arrayOf(fileName, relativePath)
                            try {
                                contentResolver.delete(collectionUri, selection, selectionArgs)
                            } catch (e: Exception) {}

                            val values = android.content.ContentValues().apply {
                                put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                                put(android.provider.MediaStore.MediaColumns.MIME_TYPE, "text/plain")
                                put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                            }

                            val uri = contentResolver.insert(collectionUri, values)
                            if (uri != null) {
                                contentResolver.openOutputStream(uri)?.use { os ->
                                    os.write(content.toByteArray(Charsets.UTF_8))
                                }
                                writeSuccess = true
                            }
                        }

                        try {
                            android.media.MediaScannerConnection.scanFile(
                                applicationContext,
                                arrayOf(file.absolutePath),
                                arrayOf("text/plain"),
                                null
                            )
                        } catch (e: Exception) {}

                        result.success(writeSuccess)
                    } catch (e: Exception) {
                        android.util.Log.e("MainActivity", "saveTextFile failed", e)
                        result.error("WRITE_ERROR", e.message, null)
                    }
                }
                "isAllFilesAccessGranted" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        result.success(android.os.Environment.isExternalStorageManager())
                    } else {
                        result.success(true)
                    }
                }
                "requestAllFilesAccess" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        try {
                            val intent = android.content.Intent(android.provider.Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                                data = android.net.Uri.parse("package:$packageName")
                                flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val intent = android.content.Intent(android.provider.Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION).apply {
                                    flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("INTENT_ERROR", e2.message, null)
                            }
                        }
                    } else {
                        result.success(true)
                    }
                }
                "cancel" -> {
                    activeTranscoder?.cancel()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
