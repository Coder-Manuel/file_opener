package manuel.plugin.file_opener

import android.content.Context
import android.content.Intent
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

/** FileOpenerPlugin */
class FileOpenerPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "file_opener")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success(mapOf("platform" to "Android", "version" to android.os.Build.VERSION.RELEASE))
            "openFile" -> openFile(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun openFile(call: MethodCall, result: Result) {
        try {
            val filePath = call.argument<String>("path")
            if (filePath == null) {
                result.success(mapOf("type" to 4, "message" to "INVALID_PATH: File path cannot be null"))
                return
            }

            val file = File(filePath)

            // Check if file exists and is readable
            if (!file.exists() || !file.canRead()) {
                result.success(mapOf("type" to 2, "message" to "FILE_NOT_FOUND: File does not exist or is not readable"))
                return
            }

            val uri = try {
                FileProvider.getUriForFile(
                    context, "${context.packageName}.fileprovider", file
                )
            } catch (_: IllegalArgumentException) {
                // Copy the file to a known directory
                val destFile = File(context.cacheDir, file.name)
                file.copyTo(destFile, overwrite = true)

                FileProvider.getUriForFile(
                    context, "${context.packageName}.fileprovider", destFile
                )
            } catch (e: Exception) {
                result.success(mapOf("type" to 4, "message" to "URI_NOT_FOUND: ${e.message}"))
                return
            }

            // Get the file MIME type
            val mimeType = getMimeType(file)

            // Create the intent
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeType)
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }

            // Start the intent
            context.startActivity(intent)
            result.success(mapOf("type" to 0, "message" to "Done"))
        } catch (e: Exception) {
            result.success(mapOf("type" to 4, "message" to "ERROR: ${e.message}"))
        }
    }

    private fun getMimeType(file: File): String {
        val extension = MimeTypeMap.getFileExtensionFromUrl(file.path)
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.lowercase()) ?: "*/*"
    }
}
