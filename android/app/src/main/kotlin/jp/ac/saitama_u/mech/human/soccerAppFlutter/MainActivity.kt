package jp.ac.saitama_u.mech.human.soccerAppFlutter

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity() {
  private val SCANNER_EVENT_CHANNEL = "human.mech.saitama-u.ac.jp/scannerEventChannel"
  private val SCANNER_METHOD_CHANNEL = "human.mech.saitama-u.ac.jp/scannerMethodChannel"

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCANNER_METHOD_CHANNEL).setMethodCallHandler {
      call, result ->
      when (call.method) {
        "startScanning" -> {
          result.success("[MethodChannel] Scanning started")
        }
        "stopScanning" -> {
          result.success("[MethodChannel] Scanning stopped")
        }
        else -> result.notImplemented()
      }
    }
  }
}
