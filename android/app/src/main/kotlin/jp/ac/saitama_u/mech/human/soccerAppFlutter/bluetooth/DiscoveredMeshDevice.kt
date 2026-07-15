package jp.ac.saitama_u.mech.human.soccerAppFlutter.bluetooth

import android.bluetooth.BluetoothDevice

/**
 * Android側で検出した、未ProvisioningのBluetooth Meshデバイス情報。
 *
 * Flutter側には表示に必要な情報だけを送るが、
 * ProvisioningServiceではBluetoothDeviceやService Dataが必要になるため、
 * Android Native側で保持しておく。
 *
 * @property bluetoothDevice BLE接続に使用するAndroidのBluetoothDevice
 * @property serviceData Mesh Provisioning Service（0x1827）のService Data
 * @property name デバイス名
 * @property rssi 電波強度
 */
data class DiscoveredMeshDevice(
    val bluetoothDevice: BluetoothDevice,
    val serviceData: ByteArray,
    val name: String,
    val rssi: Int
)