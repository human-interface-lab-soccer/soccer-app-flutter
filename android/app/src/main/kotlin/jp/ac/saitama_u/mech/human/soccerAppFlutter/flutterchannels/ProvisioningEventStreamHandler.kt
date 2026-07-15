package jp.ac.saitama_u.mech.human.soccerAppFlutter.flutterchannels

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Provisioningの進捗をAndroid NativeからFlutterへ通知するクラス。
 *
 * iOS版のProvisioningEventStreamHandler.swiftに対応する。
 */
class ProvisioningEventStreamHandler : EventChannel.StreamHandler {

    companion object {
        const val STATUS_CONNECTING = "connecting"
        const val STATUS_DISCOVERING = "discovering"
        const val STATUS_IDENTIFYING = "identifying"
        const val STATUS_PROVISIONING = "provisioning"
        const val STATUS_COMPLETE = "complete"
        const val STATUS_ERROR = "error"
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    private var eventSink: EventChannel.EventSink? = null

    /**
     * FlutterがEventChannelの購読を開始したときに呼ばれる。
     */
    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?
    ) {
        eventSink = events
    }

    /**
     * FlutterがEventChannelの購読を解除したときに呼ばれる。
     */
    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    /**
     * Provisioningの進捗をFlutterへ送る。
     *
     * @param status connecting、provisioning、completeなどの状態
     * @param data Flutterへ送る追加データ
     */
    fun sendEvent(
        status: String,
        data: Map<String, Any?> = emptyMap()
    ) {
        val sink = eventSink ?: return

        val eventData = HashMap<String, Any?>()
        eventData.putAll(data)
        eventData["status"] = status

        // EventSinkへの送信はメインスレッドで実行する。
        mainHandler.post {
            sink.success(eventData)
        }
    }

    /**
     * エラー情報をFlutterへ送る。
     */
    fun sendError(message: String) {
        sendEvent(
            status = STATUS_ERROR,
            data = mapOf("message" to message)
        )
    }
}