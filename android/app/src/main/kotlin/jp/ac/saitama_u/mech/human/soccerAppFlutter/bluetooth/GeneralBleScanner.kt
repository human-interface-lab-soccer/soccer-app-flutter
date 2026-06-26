package jp.ac.saitama_u.mech.human.soccerAppFlutter.bluetooth

import android.Manifest
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.ParcelUuid
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import java.util.UUID
import android.util.Log

private const val TAG = "GeneralBleScanner"

class GeneralBleScanner(
    private val context: Context
) : EventChannel.StreamHandler {

    companion object {
        private val MESH_PROVISIONING_SERVICE_UUID: UUID =
            UUID.fromString("00001827-0000-1000-8000-00805f9b34fb")
    }

    // ### Android側のBluetoothの機能を取得する
    private val bluetoothManager: BluetoothManager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

    // ### BlutoothAdaptarの取得
    // - Bluetoothの電源
    // - Blurtooth機能
    // - BluetoorhBleScannerの取得
    private val bluetoothAdapter
        get() = bluetoothManager.adapter

    // ### BLEスキャンを行うクラス
    private val bluetoothLeScanner
        get() = bluetoothAdapter?.bluetoothLeScanner

    //　### kotlin → flutter へデータを送る
    private var eventSink: EventChannel.EventSink? = null
    private var isScanning = false

    private val scanCallback = object : ScanCallback() {

        // ### 新しいデバイスが見つかるたびに呼ばれるメソッド
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            // 発見したデバイスを取得
            val device = result.device
            
            // デバイス名を取得
            // ※Android12以降では"BLUETOOTH_CONNECT"権限がないとdevice.nameを取得できないらしい
            // 権限がないと"Unknown device"が返る
            val deviceName = if (hasConnectPermission()) {
                device.name ?: "Unknown device"
            } else {
                "Unknown device"
            }
            
            // flutterへ送るデータのmapデータ
            val deviceData = mapOf(
                "name" to deviceName,
                "uuid" to device.address,
                "rssi" to result.rssi
            )
            
            // flutterへデータを送信
            eventSink?.success(deviceData)
        }

        override fun onScanFailed(errorCode: Int) {
            eventSink?.error(
                "SCAN_FAILED",
                "BLE scan failed. errorCode=$errorCode",
                null
            )
        }
    }

    // ### スキャンを開始する
    fun startScan() {
        // Log.d(TAG, "startScan")
        // Log.d(TAG, "eventsink = $eventSink")

        // 既にスキャン中なら何もしない
        if (isScanning) return

        // Bluetoothの権限チェック
        if (!hasScanPermission()) {
            eventSink?.error(
                "PERMISSION_DENIED",
                "BLUETOOTH_SCAN permission is not granted",
                null
            )
            return
        }

        // Bluetooth権限がONか確認する（OFFならエラーを返す）
        if (bluetoothAdapter == null || bluetoothAdapter?.isEnabled != true) {
            eventSink?.error(
                "BLUETOOTH_OFF",
                "Bluetooth is not enabled",
                null
            )
            return
        }
        
        // サービスUUIDによるフィルタ（1827というService UUIDを持つデバイスだけを見つける）
        val filter = ScanFilter.Builder()
            .setServiceUuid(ParcelUuid(MESH_PROVISIONING_SERVICE_UUID))
            .build()

        // 高速スキャンモード
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        bluetoothLeScanner?.startScan(
            listOf(filter),
            settings,
            scanCallback
        )

        isScanning = true
    }


    // ### スキャンを終了する
    fun stopScan() {
        if (!isScanning) return

        if (!hasScanPermission()) return

        bluetoothLeScanner?.stopScan(scanCallback)
        isScanning = false
    }
    
    
    // ### Flutterとの通信路を確保する
    // FlutterがreceiveBroadcastStream()を読んだ瞬間に実行される
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        // Log.d(TAG,"start onListen")
        eventSink = events


        // ダミーデータ送信テスト（検証が終わったらコメントアウト）---------------------
        // UIに表示されるかのテスト用
        val deviceData = mapOf(
            "name" to "Dummy BLE Device",
            "uuid" to "AA:BB:CC:DD:EE:FF",
            "rssi" to -45
        )

        // flutterへデータを送信
        eventSink?.success(deviceData)
        
        Log.d(TAG,"ダミーデータを送信します")
        
        // ダミーデータ送信テストここまで---------------------------------------------
    }


    // ### eventSink破壊
    // flutterが購読を解除すると，スキャン停止→eventSink破壊
    override fun onCancel(arguments: Any?) {
        stopScan()
        eventSink = null
    }

    private fun hasScanPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.BLUETOOTH_SCAN
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun hasConnectPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.BLUETOOTH_CONNECT
        ) == PackageManager.PERMISSION_GRANTED
    }
}