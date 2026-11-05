package com.example.image_editor

import com.google.android.gms.common.moduleinstall.ModuleInstall
import com.google.android.gms.common.moduleinstall.ModuleInstallRequest
import com.google.mlkit.vision.segmentation.subject.SubjectSegmentation
import com.google.mlkit.vision.segmentation.subject.SubjectSegmenterOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ensureSubjectSegmentationModel" -> ensureSubjectSegmentationModel(result)
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Makes sure Google Play services has the ML Kit subject segmentation model.
     * Replies "available" when it can be used now, or "installing" when a
     * download was requested (it continues in the background).
     */
    private fun ensureSubjectSegmentationModel(result: MethodChannel.Result) {
        val segmenter = SubjectSegmentation.getClient(
            SubjectSegmenterOptions.Builder().enableForegroundConfidenceMask().build(),
        )
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

    private companion object {
        const val CHANNEL = "chitred/ml_models"
    }
}
