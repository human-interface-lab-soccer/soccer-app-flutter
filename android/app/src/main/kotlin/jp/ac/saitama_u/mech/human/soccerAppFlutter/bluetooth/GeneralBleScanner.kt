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

    private val bluetoothManager: BluetoothManager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

    private val bluetoothAdapter
        get() = bluetoothManager.adapter

    private val bluetoothLeScanner
        get() = bluetoothAdapter?.bluetoothLeScanner

    private var eventSink: EventChannel.EventSink? = null
    private var isScanning = false

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val device = result.device

            val deviceName = if (hasConnectPermission()) {
                device.name ?: "Unknown device"
            } else {
                "Unknown device"
            }

            val deviceData = mapOf(
                "name" to deviceName,
                "uuid" to device.address,
                "rssi" to result.rssi
            )

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

    fun startScan() {
        Log.d(TAG, "スキャンが開始されました")

        if (isScanning) return

        if (!hasScanPermission()) {
            eventSink?.error(
                "PERMISSION_DENIED",
                "BLUETOOTH_SCAN permission is not granted",
                null
            )
            return
        }

        if (bluetoothAdapter == null || bluetoothAdapter?.isEnabled != true) {
            eventSink?.error(
                "BLUETOOTH_OFF",
                "Bluetooth is not enabled",
                null
            )
            return
        }

        val filter = ScanFilter.Builder()
            .setServiceUuid(ParcelUuid(MESH_PROVISIONING_SERVICE_UUID))
            .build()

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

    fun stopScan() {
        if (!isScanning) return

        if (!hasScanPermission()) return

        bluetoothLeScanner?.stopScan(scanCallback)
        isScanning = false
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

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