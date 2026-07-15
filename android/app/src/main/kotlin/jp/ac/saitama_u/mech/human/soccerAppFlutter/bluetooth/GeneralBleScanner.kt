package jp.ac.saitama_u.mech.human.soccerAppFlutter.bluetooth

import android.Manifest
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.ParcelUuid
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/**
 * 未ProvisioningのBluetooth Meshデバイスを検出するスキャナ。
 *
 * Mesh Provisioning Service UUID（0x1827）を広告している
 * BLEデバイスだけを対象にスキャンする。
 *
 * 検出結果はEventChannelを通してFlutterへ送信し、
 * Provisioningに必要なNative情報はdiscoveredDevicesへ保存する。
 */
class GeneralBleScanner(
    private val context: Context
) : EventChannel.StreamHandler {

    companion object {
        private const val TAG = "GeneralBleScanner"

        /**
         * Bluetooth Mesh Provisioning Service UUID。
         *
         * 0x1827は、まだMesh Networkへ登録されていない
         *未Provisioningデバイスが広告するService UUID。
         */
        private val MESH_PROVISIONING_SERVICE_UUID: UUID =
            UUID.fromString("00001827-0000-1000-8000-00805f9b34fb")
    }

    /**
     * Android端末のBluetooth機能を管理するクラス。
     */
    private val bluetoothManager: BluetoothManager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

    /**
     * Bluetoothアダプタ。
     *
     * Bluetoothの有効状態確認や、
     * BluetoothLeScannerの取得に使用する。
     */
    private val bluetoothAdapter
        get() = bluetoothManager.adapter

    /**
     * BLEスキャンを実行するAndroid API。
     */
    private val bluetoothLeScanner
        get() = bluetoothAdapter?.bluetoothLeScanner

    /**
     * KotlinからFlutterへイベントを送るための送信口。
     */
    private var eventSink: EventChannel.EventSink? = null

    /**
     * 現在スキャン中かどうか。
     */
    private var isScanning = false

    /**
     * 発見済みの未Provisioningデバイス一覧。
     *
     * キーにはBluetoothアドレスを使用する。
     * Flutter側の既存仕様では、この値をuuidとして扱っている。
     */
    val discoveredDevices:
        MutableMap<String, DiscoveredMeshDevice> = ConcurrentHashMap()

    /**
     * BLEスキャン結果を受け取るコールバック。
     */
    private val scanCallback = object : ScanCallback() {

        /**
         * BLEデバイスが検出されるたびに呼ばれる。
         */
        override fun onScanResult(
            callbackType: Int,
            result: ScanResult
        ) {
            val scanRecord = result.scanRecord ?: return

            /**
             * 0x1827のService Dataを取得する。
             *
             * Provisioning時にMesh Device UUIDを取得するために使用する。
             */
            val serviceData = scanRecord.getServiceData(
                ParcelUuid(MESH_PROVISIONING_SERVICE_UUID)
            ) ?: return

            if (!hasConnectPermission()) {
                eventSink?.error(
                    "PERMISSION_DENIED",
                    "BLUETOOTH_CONNECT permission is not granted",
                    null
                )
                return
            }

            val device = result.device
            val deviceName = device.name ?: "Unknown device"

            /**
             * AndroidではBluetoothアドレスをデバイス識別用キーとして使う。
             *
             * Flutter側ではuuidという名前で扱っているが、
             * Androidでは実際にはMACアドレスに相当する値。
             */
            val deviceId = device.address

            /**
             * Provisioningで必要になる情報をAndroid側へ保存する。
             *
             * 同じデバイスが再度検出された場合は、
             * 最新のRSSIやService Dataで上書きされる。
             */
            discoveredDevices[deviceId] = DiscoveredMeshDevice(
                bluetoothDevice = device,
                serviceData = serviceData.copyOf(),
                name = deviceName,
                rssi = result.rssi
            )

            /**
             * Flutterへ送信するデータ。
             *
             * Dart側のBleDevice.fromMap()が期待しているキー名に合わせる。
             */
            val deviceData = mapOf(
                "name" to deviceName,
                "uuid" to deviceId,
                "rssi" to result.rssi
            )

            eventSink?.success(deviceData)
        }

        /**
         * BLEスキャンに失敗したときに呼ばれる。
         */
        override fun onScanFailed(errorCode: Int) {
            isScanning = false

            Log.e(
                TAG,
                "BLE scan failed. errorCode=$errorCode"
            )

            eventSink?.error(
                "SCAN_FAILED",
                "BLE scan failed. errorCode=$errorCode",
                null
            )
        }
    }

    /**
     * 未ProvisioningのMeshデバイスのスキャンを開始する。
     */
    fun startScan() {
        if (isScanning) {
            return
        }

        if (!hasScanPermission()) {
            eventSink?.error(
                "PERMISSION_DENIED",
                "Bluetooth scan permission is not granted",
                null
            )
            return
        }

        if (!hasConnectPermission()) {
            eventSink?.error(
                "PERMISSION_DENIED",
                "Bluetooth connect permission is not granted",
                null
            )
            return
        }

        val adapter = bluetoothAdapter

        if (adapter == null) {
            eventSink?.error(
                "BLUETOOTH_UNSUPPORTED",
                "Bluetooth is not supported on this device",
                null
            )
            return
        }

        if (!adapter.isEnabled) {
            eventSink?.error(
                "BLUETOOTH_OFF",
                "Bluetooth is not enabled",
                null
            )
            return
        }

        val scanner = bluetoothLeScanner

        if (scanner == null) {
            eventSink?.error(
                "SCANNER_UNAVAILABLE",
                "Bluetooth LE scanner is unavailable",
                null
            )
            return
        }

        /**
         * 新しいスキャンを始めるため、
         * 前回保存した検出結果を削除する。
         */
        discoveredDevices.clear()

        /**
         * Mesh Provisioning Service（0x1827）を持つ
         * デバイスだけに絞り込む。
         */
        val scanFilter = ScanFilter.Builder()
            .setServiceUuid(
                ParcelUuid(MESH_PROVISIONING_SERVICE_UUID)
            )
            .build()

        /**
         * 検出速度を優先したスキャン設定。
         *
         * バッテリー消費は増えるため、
         * 必要がなくなったらstopScan()を呼ぶ。
         */
        val scanSettings = ScanSettings.Builder()
            .setScanMode(
                ScanSettings.SCAN_MODE_LOW_LATENCY
            )
            .build()

        scanner.startScan(
            listOf(scanFilter),
            scanSettings,
            scanCallback
        )

        isScanning = true
        Log.d(TAG, "Mesh Provisioning scan started")
    }

    /**
     * BLEスキャンを停止する。
     */
    fun stopScan() {
        if (!isScanning) {
            return
        }

        if (!hasScanPermission()) {
            isScanning = false
            return
        }

        bluetoothLeScanner?.stopScan(scanCallback)
        isScanning = false

        Log.d(TAG, "Mesh Provisioning scan stopped")
    }

    /**
     * 保存済みデバイスから、指定されたIDのデバイスを取得する。
     *
     * ProvisioningServiceから使用する。
     */
    fun getDiscoveredDevice(
        deviceId: String
    ): DiscoveredMeshDevice? {
        return discoveredDevices[deviceId]
    }

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
        stopScan()
        eventSink = null
    }

    /**
     * BLEスキャンに必要な権限が許可されているか確認する。
     */
    private fun hasScanPermission(): Boolean {
        return if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
        ) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH_SCAN
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        }
    }

    /**
     * Bluetoothデバイス情報の取得・接続に必要な権限を確認する。
     */
    private fun hasConnectPermission(): Boolean {
        return if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
        ) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }
}