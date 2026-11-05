package com.example.image_editor

import android.os.Handler
import android.os.Looper
import com.google.android.gms.common.moduleinstall.InstallStatusListener
import com.google.android.gms.common.moduleinstall.ModuleInstall
import com.google.android.gms.common.moduleinstall.ModuleInstallClient
import com.google.android.gms.common.moduleinstall.ModuleInstallRequest
import com.google.android.gms.common.moduleinstall.ModuleInstallStatusUpdate
import com.google.android.gms.common.moduleinstall.ModuleInstallStatusUpdate.InstallState
import com.google.mlkit.vision.segmentation.subject.SubjectSegmentation
import com.google.mlkit.vision.segmentation.subject.SubjectSegmenter
import com.google.mlkit.vision.segmentation.subject.SubjectSegmenterOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "ensureSubjectSegmentationModel" -> ensureSubjectSegmentationModel(result)
                "isSubjectSegmentationModelAvailable" -> isSubjectSegmentationModelAvailable(result)
                else -> result.notImplemented()
            }
        }
        EventChannel(messenger, DOWNLOAD_CHANNEL).setStreamHandler(ModelDownloadHandler())
    }

    private fun newSegmenter(): SubjectSegmenter = SubjectSegmentation.getClient(
        SubjectSegmenterOptions.Builder().enableForegroundConfidenceMask().build(),
    )

    /** Replies whether the subject segmentation model is installed. */
    private fun isSubjectSegmentationModelAvailable(result: MethodChannel.Result) {
        val segmenter = newSegmenter()
        ModuleInstall.getClient(this).areModulesAvailable(segmenter)
            .addOnSuccessListener { availability ->
                segmenter.close()
                result.success(availability.areModulesAvailable())
            }
            .addOnFailureListener { error ->
                segmenter.close()
                result.error("MODEL_CHECK_FAILED", error.message, null)
            }
    }

    /**
     * Makes sure Google Play services has the ML Kit subject segmentation model.
     * Replies "available" when it can be used now, or "installing" when a
     * download was requested (it continues in the background).
     */
    private fun ensureSubjectSegmentationModel(result: MethodChannel.Result) {
        val segmenter = newSegmenter()
        val installer = ModuleInstall.getClient(this)
        installer.areModulesAvailable(segmenter)
            .addOnSuccessListener { availability ->
                if (availability.areModulesAvailable()) {
                    segmenter.close()
                    result.success("available")
                    return@addOnSuccessListener
                }
                val request = ModuleInstallRequest.newBuilder().addApi(segmenter).build()
                installer.installModules(request)
                    .addOnSuccessListener { response ->
                        segmenter.close()
                        result.success(if (response.areModulesAlreadyInstalled()) "available" else "installing")
                    }
                    .addOnFailureListener { error ->
                        segmenter.close()
                        result.error("MODEL_INSTALL_FAILED", error.message, null)
                    }
            }
            .addOnFailureListener { error ->
                segmenter.close()
                result.error("MODEL_CHECK_FAILED", error.message, null)
            }
    }

    /**
     * Downloads the model while Dart listens, streaming
     * `{"downloaded": bytes, "total": bytes}` progress events. The stream ends
     * when the model is installed and errors if the download fails.
     */
    private inner class ModelDownloadHandler : EventChannel.StreamHandler {
        private var installer: ModuleInstallClient? = null
        private var segmenter: SubjectSegmenter? = null
        private var listener: InstallStatusListener? = null
        private var finished = false

        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            cleanUp()
            finished = false
            val client = ModuleInstall.getClient(this@MainActivity)
            val api = newSegmenter()
            val statusListener = InstallStatusListener { update -> mainHandler.post { onUpdate(update, events) } }
            installer = client
            segmenter = api
            listener = statusListener

            val request = ModuleInstallRequest.newBuilder()
                .addApi(api)
                .setListener(statusListener)
                .build()
            client.installModules(request)
                .addOnSuccessListener { response ->
                    if (response.areModulesAlreadyInstalled()) finish { events.endOfStream() }
                }
                .addOnFailureListener { error ->
                    finish { events.error("MODEL_INSTALL_FAILED", error.message, null) }
                }
        }

        private fun onUpdate(update: ModuleInstallStatusUpdate, events: EventChannel.EventSink) {
            if (finished) return
            when (update.installState) {
                InstallState.STATE_COMPLETED -> finish { events.endOfStream() }
                InstallState.STATE_FAILED, InstallState.STATE_CANCELED -> finish {
                    events.error(
                        "MODEL_DOWNLOAD_FAILED",
                        "install state ${update.installState}, error ${update.errorCode}",
                        null,
                    )
                }
                else -> {
                    val progress = update.progressInfo
                    events.success(
                        mapOf(
                            "downloaded" to (progress?.bytesDownloaded ?: 0L),
                            "total" to (progress?.totalBytesToDownload ?: 0L),
                        ),
                    )
                }
            }
        }

        private fun finish(report: () -> Unit) {
            if (finished) return
            finished = true
            report()
            cleanUp()
        }

        override fun onCancel(arguments: Any?) {
            finished = true
            cleanUp()
        }

        private fun cleanUp() {
            listener?.let { installer?.unregisterListener(it) }
            segmenter?.close()
            listener = null
            segmenter = null
            installer = null
        }
    }

    private companion object {
        const val CHANNEL = "chitred/ml_models"
        const val DOWNLOAD_CHANNEL = "chitred/ml_models/download"
    }
}
