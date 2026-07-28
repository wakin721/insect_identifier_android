package top.myneri.insectidentifier

import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import com.ultralytics.yolo.YOLOInstanceManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Runs still-image YOLO classification away from Android's main thread.
 *
 * ultralytics_yolo 0.6.10 performs predictSingleImage synchronously in its
 * MethodChannel handler. Keeping a project-owned channel avoids blocking
 * Flutter frames while retaining the plugin's model lifecycle.
 */
class BackgroundYoloChannel(binaryMessenger: BinaryMessenger) {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val inferenceExecutor: ExecutorService =
        Executors.newSingleThreadExecutor { runnable ->
            Thread(runnable, "insect-yolo-inference")
        }
    private val channel =
        MethodChannel(binaryMessenger, CHANNEL_NAME)

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "predictSingleImage" -> {
                    val imageData = call.argument<ByteArray>("image")
                    if (imageData == null) {
                        result.error("bad_args", "No image data", null)
                        return@setMethodCallHandler
                    }
                    val instanceId =
                        call.argument<String>("instanceId") ?: DEFAULT_INSTANCE_ID
                    val confidenceThreshold =
                        call.argument<Double>("confidenceThreshold")?.toFloat()
                    val iouThreshold =
                        call.argument<Double>("iouThreshold")?.toFloat()
                    predict(
                        imageData = imageData,
                        instanceId = instanceId,
                        confidenceThreshold = confidenceThreshold,
                        iouThreshold = iouThreshold,
                        result = result,
                    )
                }
                "predictorInstance" -> {
                    val instanceId =
                        call.argument<String>("instanceId") ?: DEFAULT_INSTANCE_ID
                    instantiatePredictor(instanceId, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun instantiatePredictor(
        instanceId: String,
        result: MethodChannel.Result,
    ) {
        inferenceExecutor.execute {
            try {
                if (!YOLOInstanceManager.shared.hasInstance(instanceId)) {
                    postError(
                        result,
                        "model_not_loaded",
                        "No model loaded for instance $instanceId",
                    )
                    return@execute
                }
                YOLOInstanceManager.shared.predictorInstance(instanceId)
                mainHandler.post { result.success(null) }
            } catch (error: Exception) {
                postError(
                    result,
                    "predictor_instance_error",
                    error.message ?: error.javaClass.simpleName,
                )
            }
        }
    }

    private fun predict(
        imageData: ByteArray,
        instanceId: String,
        confidenceThreshold: Float?,
        iouThreshold: Float?,
        result: MethodChannel.Result,
    ) {
        inferenceExecutor.execute {
            val bitmap = BitmapFactory.decodeByteArray(
                imageData,
                0,
                imageData.size,
            )
            if (bitmap == null) {
                postError(result, "image_error", "Failed to decode image")
                return@execute
            }

            try {
                val yoloResult = YOLOInstanceManager.shared.predict(
                    instanceId,
                    bitmap,
                    confidenceThreshold,
                    iouThreshold,
                )
                val probabilities = yoloResult?.probs
                if (probabilities == null) {
                    postError(
                        result,
                        "prediction_error",
                        "The classifier did not return probabilities",
                    )
                    return@execute
                }

                val topFive =
                    probabilities.top5Labels
                        .zip(probabilities.top5Confs.toList())
                        .map { (label, confidence) ->
                            mapOf<String, Any>(
                                "name" to label,
                                "confidence" to confidence.toDouble(),
                            )
                        }
                val response = mapOf<String, Any>(
                    "classification" to mapOf(
                        "name" to probabilities.top1Label,
                        "class" to probabilities.top1Index,
                        "confidence" to probabilities.top1Conf.toDouble(),
                        "top5" to topFive,
                    ),
                )
                mainHandler.post { result.success(response) }
            } catch (error: Exception) {
                postError(
                    result,
                    "prediction_error",
                    error.message ?: error.javaClass.simpleName,
                )
            } finally {
                bitmap.recycle()
            }
        }
    }

    private fun postError(
        result: MethodChannel.Result,
        code: String,
        message: String,
    ) {
        mainHandler.post { result.error(code, message, null) }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        inferenceExecutor.shutdownNow()
    }

    companion object {
        private const val CHANNEL_NAME =
            "top.myneri.insectidentifier/background_yolo"
        private const val DEFAULT_INSTANCE_ID = "default"
    }
}
