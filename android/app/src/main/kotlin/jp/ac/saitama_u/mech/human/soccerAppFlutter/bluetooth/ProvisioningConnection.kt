package jp.ac.saitama_u.mech.human.soccerAppFlutter.bluetooth

import android.Manifest
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothStatusCodes
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import java.util.ArrayDeque
import java.util.UUID

/**
 * 未ProvisioningのBluetooth Meshデバイスとの
 * BLE GATT通信を管理するクラス。
 *
 * 主な役割:
 * ・対象デバイスへの接続
 * ・Mesh Provisioning Serviceの探索
 * ・Provisioning Data Out通知の有効化
 * ・Provisioning Data InへのPDU書き込み
 * ・受信データや接続状態をProvisioningServiceへ通知
 */
class ProvisioningConnection(
    private val context: Context,
    private val listener: Listener
) {

    interface Listener {

        fun onConnecting()

        fun onConnected()

        fun onDiscoveringServices()

        /**
         * Provisioning用Characteristicの準備完了時に呼ばれる。
         *
         * @param mtu Androidから通知されたATT MTU
         */
        fun onReady(mtu: Int)

        fun onNotificationReceived(data: ByteArray)

        /**
         * 1つのGATT SARパケットの書き込みが完了するたびに呼ばれる。
         */
        fun onWriteCompleted(data: ByteArray)

        fun onDisconnected(message: String?)

        fun onError(message: String)
    }

    companion object {
        private const val TAG = "ProvisioningConnection"

        /** Mesh Provisioning Service: 0x1827 */
        private val MESH_PROVISIONING_SERVICE_UUID: UUID =
            UUID.fromString(
                "00001827-0000-1000-8000-00805f9b34fb"
            )

        /** Provisioning Data In: 0x2ADB */
        private val PROVISIONING_DATA_IN_UUID: UUID =
            UUID.fromString(
                "00002adb-0000-1000-8000-00805f9b34fb"
            )

        /** Provisioning Data Out: 0x2ADC */
        private val PROVISIONING_DATA_OUT_UUID: UUID =
            UUID.fromString(
                "00002adc-0000-1000-8000-00805f9b34fb"
            )

        /** Client Characteristic Configuration Descriptor */
        private val CCCD_UUID: UUID =
            UUID.fromString(
                "00002902-0000-1000-8000-00805f9b34fb"
            )

        private const val REQUESTED_MTU = 247
        private const val DEFAULT_ATT_MTU = 23

        /**
         * ATT Write Request/Commandのヘッダー分。
         *
         * Characteristicへ書き込めるデータサイズは、
         * 基本的にATT MTU - 3。
         */
        private const val ATT_WRITE_HEADER_SIZE = 3

        /** ATT MTU 23の場合に書き込める標準ペイロードサイズ */
        private const val DEFAULT_GATT_PAYLOAD_SIZE = 20
    }

    private var bluetoothGatt: BluetoothGatt? = null

    private var provisioningDataIn:
        BluetoothGattCharacteristic? = null

    private var provisioningDataOut:
        BluetoothGattCharacteristic? = null

    /**
     * Androidから通知されたATT MTU。
     *
     * 例:
     * ATT MTU 33なら、Characteristicへ書き込めるサイズは30バイト。
     */
    private var currentAttMtu = DEFAULT_ATT_MTU

    /**
     * Nordic Mesh SDKから渡されたデータを、
     * GATTへ書き込めるサイズに区切って保持するキュー。
     */
    private val writeQueue = ArrayDeque<ByteArray>()

    /**
     * 現在Characteristicへ書き込み中のデータ。
     */
    private var currentWriteData: ByteArray? = null

    private var isWriting = false
    private var isReady = false
    private var isDisconnectRequested = false

    private val gattCallback = object : BluetoothGattCallback() {

        override fun onConnectionStateChange(
            gatt: BluetoothGatt,
            status: Int,
            newState: Int
        ) {
            Log.d(
                TAG,
                "onConnectionStateChange: " +
                    "status=$status, newState=$newState"
            )

            /*
             * status=0以外の場合はGATTレベルのエラー。
             *
             * status=19は接続先からの切断として返されることがある。
             */
            if (status != BluetoothGatt.GATT_SUCCESS) {
                val message =
                    "GATT connection failed. status=$status"

                Log.e(TAG, message)

                listener.onError(message)
                closeGatt(gatt)
                return
            }

            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    Log.d(TAG, "Provisioning device connected")

                    listener.onConnected()

                    val mtuRequestStarted =
                        gatt.requestMtu(REQUESTED_MTU)

                    if (!mtuRequestStarted) {
                        currentAttMtu = DEFAULT_ATT_MTU
                        startServiceDiscovery(gatt)
                    }
                }

                BluetoothProfile.STATE_DISCONNECTED -> {
                    Log.d(TAG, "Provisioning device disconnected")

                    val manuallyDisconnected =
                        isDisconnectRequested

                    closeGatt(gatt)

                    listener.onDisconnected(
                        if (manuallyDisconnected) {
                            null
                        } else {
                            "Provisioning device disconnected."
                        }
                    )
                }
            }
        }

        override fun onMtuChanged(
            gatt: BluetoothGatt,
            mtu: Int,
            status: Int
        ) {
            currentAttMtu =
                if (status == BluetoothGatt.GATT_SUCCESS) {
                    mtu
                } else {
                    DEFAULT_ATT_MTU
                }

            Log.d(
                TAG,
                "ATT MTU=$currentAttMtu, " +
                    "GATT payload=${getGattPayloadSize()}"
            )

            startServiceDiscovery(gatt)
        }

        override fun onServicesDiscovered(
            gatt: BluetoothGatt,
            status: Int
        ) {
            Log.d(
                TAG,
                "onServicesDiscovered: status=$status"
            )

            if (status != BluetoothGatt.GATT_SUCCESS) {
                reportError(
                    "Service discovery failed. status=$status"
                )
                return
            }

            val provisioningService =
                gatt.getService(
                    MESH_PROVISIONING_SERVICE_UUID
                )

            if (provisioningService == null) {
                reportError(
                    "Mesh Provisioning Service (0x1827) " +
                        "was not found."
                )
                return
            }

            Log.d(TAG, "Mesh Provisioning Service found")

            provisioningDataIn =
                provisioningService.getCharacteristic(
                    PROVISIONING_DATA_IN_UUID
                )

            provisioningDataOut =
                provisioningService.getCharacteristic(
                    PROVISIONING_DATA_OUT_UUID
                )

            if (provisioningDataIn == null) {
                reportError(
                    "Provisioning Data In characteristic " +
                        "(0x2ADB) was not found."
                )
                return
            }

            val dataOut = provisioningDataOut

            if (dataOut == null) {
                reportError(
                    "Provisioning Data Out characteristic " +
                        "(0x2ADC) was not found."
                )
                return
            }

            Log.d(
                TAG,
                "Provisioning Data In and Data Out found"
            )

            enableProvisioningNotifications(
                gatt = gatt,
                characteristic = dataOut
            )
        }

        override fun onDescriptorWrite(
            gatt: BluetoothGatt,
            descriptor: BluetoothGattDescriptor,
            status: Int
        ) {
            if (descriptor.uuid != CCCD_UUID) {
                return
            }

            if (status != BluetoothGatt.GATT_SUCCESS) {
                reportError(
                    "Failed to enable provisioning notifications. " +
                        "status=$status"
                )
                return
            }

            isReady = true

            Log.d(
                TAG,
                "Provisioning notification enabled"
            )

            listener.onReady(currentAttMtu)
        }

        /**
         * Android 13以上で利用される通知Callback。
         */
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray
        ) {
            handleCharacteristicNotification(
                characteristic = characteristic,
                value = value
            )
        }

        /**
         * Android 12以下で利用される通知Callback。
         */
        @Deprecated("Deprecated in Android API 33")
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic
        ) {
            val value = characteristic.value ?: return

            handleCharacteristicNotification(
                characteristic = characteristic,
                value = value
            )
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int
        ) {
            if (
                characteristic.uuid !=
                PROVISIONING_DATA_IN_UUID
            ) {
                return
            }

            val writtenData = currentWriteData

            currentWriteData = null
            isWriting = false

            Log.d(
                TAG,
                "Provisioning chunk written: " +
                    "status=$status, " +
                    "size=${writtenData?.size ?: 0}"
            )

            if (status != BluetoothGatt.GATT_SUCCESS) {
                clearWriteQueue()

                reportError(
                    "Failed to write provisioning PDU. " +
                        "status=$status"
                )
                return
            }

            /*
             * Nordic Mesh SDKへ、
             * 実際に書き込んだGATT SARパケットを返す。
             *
             * SDK側は複数のパケットを再構成し、
             * 最後のパケットまで完了すると次の状態へ進む。
             */
            if (writtenData != null) {
                listener.onWriteCompleted(
                    writtenData.copyOf()
                )
            }

            writeNextPacket()
        }
    }

    /**
     * 未Provisioningデバイスへの接続を開始する。
     */
    fun connect(device: BluetoothDevice) {
        if (!hasConnectPermission()) {
            listener.onError(
                "BLUETOOTH_CONNECT permission is not granted."
            )
            return
        }

        close()

        isDisconnectRequested = false
        isReady = false
        currentAttMtu = DEFAULT_ATT_MTU

        listener.onConnecting()

        Log.d(
            TAG,
            "Connecting to provisioning device"
        )

        bluetoothGatt = device.connectGatt(
            context,
            false,
            gattCallback,
            BluetoothDevice.TRANSPORT_LE
        )
    }

    /**
     * Nordic Mesh SDKが生成したProvisioning用データを、
     * GATTへ順番に書き込む。
     *
     * Nordic Mesh SDK側ですでにGATT SARヘッダーが付加され、
     * 1つのByteArrayへ連結されている。
     *
     * そのため、ここではSARを新しく付け直さず、
     * SDKのgetMtu()と同じサイズごとに切り分ける。
     */
    fun writeProvisioningPdu(data: ByteArray) {
        if (!hasConnectPermission()) {
            listener.onError(
                "BLUETOOTH_CONNECT permission is not granted."
            )
            return
        }

        if (!isReady) {
            listener.onError(
                "Provisioning GATT connection is not ready."
            )
            return
        }

        if (
            bluetoothGatt == null ||
            provisioningDataIn == null
        ) {
            listener.onError(
                "Provisioning Data In characteristic " +
                    "is unavailable."
            )
            return
        }

        val packetSize = getGattPayloadSize()

        /*
         * MeshManagerApi.applySegmentation()が作成した
         * 連結済みGATT SARパケットを、packetSizeごとに分ける。
         *
         * 例:
         * ATT MTU = 33
         * packetSize = 30
         *
         * 69バイトのデータなら:
         * 30 + 30 + 9
         */
        var offset = 0
        var addedPacketCount = 0

        while (offset < data.size) {
            val end =
                minOf(
                    offset + packetSize,
                    data.size
                )

            val packet =
                data.copyOfRange(offset, end)

            writeQueue.addLast(packet)

            offset = end
            addedPacketCount++
        }

        Log.d(
            TAG,
            "Provisioning data queued: " +
                "total=${data.size}, " +
                "packets=$addedPacketCount, " +
                "packetSize=$packetSize"
        )

        writeNextPacket()
    }

    /**
     * 書き込みキューの先頭データを1つだけ送信する。
     *
     * 次のデータはonCharacteristicWrite()後に送信するため、
     * 複数のGATT書き込みが同時に走らない。
     */
    private fun writeNextPacket() {
        if (isWriting) {
            return
        }

        val packet = writeQueue.pollFirst()
            ?: return

        val gatt = bluetoothGatt
        val characteristic = provisioningDataIn

        if (gatt == null || characteristic == null) {
            clearWriteQueue()

            listener.onError(
                "Provisioning GATT connection is unavailable."
            )
            return
        }

        isWriting = true
        currentWriteData = packet

        Log.d(
            TAG,
            "Writing provisioning packet: " +
                "${packet.size} bytes"
        )

        val writeStarted =
            if (
                Build.VERSION.SDK_INT >=
                Build.VERSION_CODES.TIRAMISU
            ) {
                val result =
                    gatt.writeCharacteristic(
                        characteristic,
                        packet,
                        BluetoothGattCharacteristic
                            .WRITE_TYPE_NO_RESPONSE
                    )

                result == BluetoothStatusCodes.SUCCESS
            } else {
                @Suppress("DEPRECATION")
                characteristic.writeType =
                    BluetoothGattCharacteristic
                        .WRITE_TYPE_NO_RESPONSE

                @Suppress("DEPRECATION")
                characteristic.value = packet

                @Suppress("DEPRECATION")
                gatt.writeCharacteristic(characteristic)
            }

        if (!writeStarted) {
            currentWriteData = null
            isWriting = false
            clearWriteQueue()

            listener.onError(
                "Failed to start writing provisioning PDU."
            )
        }
    }

    /**
     * 接続を切断する。
     */
    fun disconnect() {
        isDisconnectRequested = true
        isReady = false

        clearWriteQueue()

        if (!hasConnectPermission()) {
            close()
            return
        }

        bluetoothGatt?.disconnect()
    }

    /**
     * GATT接続を完全に破棄する。
     */
    fun close() {
        isDisconnectRequested = true
        isReady = false

        clearWriteQueue()

        val gatt = bluetoothGatt

        if (
            gatt != null &&
            hasConnectPermission()
        ) {
            /*
             * 新しい接続を始める前の破棄処理なので、
             * 接続解除を要求してからcloseする。
             */
            gatt.disconnect()
            gatt.close()
        }

        bluetoothGatt = null
        provisioningDataIn = null
        provisioningDataOut = null
        currentAttMtu = DEFAULT_ATT_MTU
    }

    /**
     * Androidから通知されたATT MTUを返す。
     */
    fun getAttMtu(): Int {
        return currentAttMtu
    }

    /**
     * Characteristicへ1回で書き込めるデータサイズを返す。
     */
    fun getGattPayloadSize(): Int {
        return (
            currentAttMtu - ATT_WRITE_HEADER_SIZE
        ).coerceAtLeast(
            DEFAULT_GATT_PAYLOAD_SIZE
        )
    }

    private fun startServiceDiscovery(
        gatt: BluetoothGatt
    ) {
        listener.onDiscoveringServices()

        Log.d(TAG, "Starting service discovery")

        if (!gatt.discoverServices()) {
            reportError(
                "Failed to start GATT service discovery."
            )
        }
    }

    private fun enableProvisioningNotifications(
        gatt: BluetoothGatt,
        characteristic: BluetoothGattCharacteristic
    ) {
        val notificationEnabled =
            gatt.setCharacteristicNotification(
                characteristic,
                true
            )

        if (!notificationEnabled) {
            reportError(
                "Failed to enable local provisioning notifications."
            )
            return
        }

        val descriptor =
            characteristic.getDescriptor(CCCD_UUID)

        if (descriptor == null) {
            reportError(
                "Provisioning notification descriptor " +
                    "was not found."
            )
            return
        }

        val writeStarted =
            if (
                Build.VERSION.SDK_INT >=
                Build.VERSION_CODES.TIRAMISU
            ) {
                val result =
                    gatt.writeDescriptor(
                        descriptor,
                        BluetoothGattDescriptor
                            .ENABLE_NOTIFICATION_VALUE
                    )

                result == BluetoothStatusCodes.SUCCESS
            } else {
                @Suppress("DEPRECATION")
                descriptor.value =
                    BluetoothGattDescriptor
                        .ENABLE_NOTIFICATION_VALUE

                @Suppress("DEPRECATION")
                gatt.writeDescriptor(descriptor)
            }

        if (!writeStarted) {
            reportError(
                "Failed to start writing " +
                    "notification descriptor."
            )
        }
    }

    private fun handleCharacteristicNotification(
        characteristic: BluetoothGattCharacteristic,
        value: ByteArray
    ) {
        if (
            characteristic.uuid !=
            PROVISIONING_DATA_OUT_UUID
        ) {
            return
        }

        Log.d(
            TAG,
            "Provisioning notification received: " +
                "${value.size} bytes"
        )

        listener.onNotificationReceived(
            value.copyOf()
        )
    }

    private fun clearWriteQueue() {
        writeQueue.clear()
        currentWriteData = null
        isWriting = false
    }

    private fun reportError(message: String) {
        Log.e(TAG, message)
        listener.onError(message)
    }

    private fun closeGatt(gatt: BluetoothGatt) {
        if (hasConnectPermission()) {
            gatt.close()
        }

        if (bluetoothGatt === gatt) {
            bluetoothGatt = null
        }

        provisioningDataIn = null
        provisioningDataOut = null
        currentAttMtu = DEFAULT_ATT_MTU
        isReady = false

        clearWriteQueue()
    }

    private fun hasConnectPermission(): Boolean {
        return if (
            Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.S
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