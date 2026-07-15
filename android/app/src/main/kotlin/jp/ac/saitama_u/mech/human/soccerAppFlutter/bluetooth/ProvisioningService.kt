package jp.ac.saitama_u.mech.human.soccerAppFlutter.bluetooth

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import jp.ac.saitama_u.mech.human.soccerAppFlutter.flutterchannels.ProvisioningEventStreamHandler
import no.nordicsemi.android.mesh.MeshManagerApi
import no.nordicsemi.android.mesh.MeshManagerCallbacks
import no.nordicsemi.android.mesh.MeshNetwork
import no.nordicsemi.android.mesh.MeshProvisioningStatusCallbacks
import no.nordicsemi.android.mesh.MeshStatusCallbacks
import no.nordicsemi.android.mesh.provisionerstates.ProvisioningState
import no.nordicsemi.android.mesh.provisionerstates.UnprovisionedMeshNode
import no.nordicsemi.android.mesh.transport.ControlMessage
import no.nordicsemi.android.mesh.transport.MeshMessage
import no.nordicsemi.android.mesh.transport.ProvisionedMeshNode
import java.util.UUID

/**
 * 未ProvisioningのBluetooth Meshデバイスを
 * Mesh Networkへ登録する処理を管理するクラス。
 *
 * 役割:
 * ・FlutterからProvisioning開始命令を受け取る
 * ・スキャン済みデバイスを取得する
 * ・ProvisioningConnectionへBLE接続を依頼する
 * ・Nordic Mesh SDKへ受信データを渡す
 * ・SDKが生成したPDUをProvisioningConnectionへ渡す
 * ・Provisioning進捗をFlutterへ通知する
 */
class ProvisioningService(
    context: Context,
    private val meshManagerApi: MeshManagerApi,
    private val bleScanner: GeneralBleScanner,
    private val eventHandler: ProvisioningEventStreamHandler
) : MeshManagerCallbacks,
    MeshProvisioningStatusCallbacks,
    MeshStatusCallbacks,
    ProvisioningConnection.Listener {

    companion object {
        private const val TAG = "ProvisioningService"

        /**
         * 対象デバイスを識別状態にする時間。
         * iOS版のattentionTimer = 5と対応する。
         */
        private const val ATTENTION_TIMER_SECONDS = 5

        /**
         * MTUネゴシエーション前の初期値。
         */
        private const val DEFAULT_MTU = 23
    }

    /**
     * Provisioning対象とのGATT通信を担当する。
     */
    private val provisioningConnection =
        ProvisioningConnection(
            context = context.applicationContext,
            listener = this
        )

    /**
     * 現在読み込まれているMesh Network。
     */
    private var meshNetwork: MeshNetwork? = null

    /**
     * 現在Provisioning対象になっているデバイス。
     */
    private var targetDevice: DiscoveredMeshDevice? = null

    /**
     * Mesh Provisioning Service Dataから取得した
     * Bluetooth Mesh固有のDevice UUID。
     */
    private var targetMeshDeviceUuid: UUID? = null

    /**
     * 現在のBLE MTU。
     */
    private var currentMtu = DEFAULT_MTU

    /**
     * Provisioning処理が正常終了したか。
     *
     * Provisioning完了後の意図的な切断を
     * エラーとしてFlutterへ通知しないために使用する。
     */
    private var provisioningCompleted = false

    init {
        meshManagerApi.setMeshManagerCallbacks(this)
        meshManagerApi.setProvisioningStatusCallbacks(this)
        meshManagerApi.setMeshStatusCallbacks(this)

        meshManagerApi.loadMeshNetwork()
    }

    /**
     * Flutterから呼び出されるProvisioning開始処理。
     *
     * @param deviceId Flutter側ではuuidと呼んでいるが、
     * Android側ではスキャン時のBluetoothアドレス。
     */
    fun startProvisioningProcess(
        deviceId: String,
        result: MethodChannel.Result
    ) {
        cleanupProvisioningState(closeConnection = true)

        val discoveredDevice =
            bleScanner.getDiscoveredDevice(deviceId)

        if (discoveredDevice == null) {
            respond(
                result = result,
                isSuccess = false,
                message = "Device not found in scan results."
            )
            return
        }

        if (meshNetwork == null) {
            respond(
                result = result,
                isSuccess = false,
                message = "Mesh Network is not ready."
            )
            return
        }

        val meshDeviceUuid = try {
            /*
             * 0x1827のService Dataから、
             * Bluetooth Mesh Device UUIDを取り出す。
             */
            meshManagerApi.getDeviceUuid(
                discoveredDevice.serviceData
            )
        } catch (exception: IllegalArgumentException) {
            Log.e(
                TAG,
                "Invalid Mesh Provisioning Service Data",
                exception
            )

            respond(
                result = result,
                isSuccess = false,
                message = exception.message
                    ?: "Failed to obtain Mesh Device UUID."
            )
            return
        }

        targetDevice = discoveredDevice
        targetMeshDeviceUuid = meshDeviceUuid
        provisioningCompleted = false

        /*
         * Provisioning中はBLEスキャンを停止する。
         */
        bleScanner.stopScan()

        /*
         * 未ProvisioningデバイスへGATT接続する。
         */
        provisioningConnection.connect(
            discoveredDevice.bluetoothDevice
        )

        respond(
            result = result,
            isSuccess = true,
            message = "Provisioning process initiated."
        )
    }

    /**
     * Activity破棄時などに使用する。
     */
    fun close() {
        cleanupProvisioningState(closeConnection = true)
    }

    // -------------------------------------------------------------------------
    // ProvisioningConnection.Listener
    // -------------------------------------------------------------------------

    override fun onConnecting() {
        eventHandler.sendEvent(
            status = ProvisioningEventStreamHandler.STATUS_CONNECTING,
            data = mapOf(
                "message" to
                    "Connecting to ${targetDevice?.name ?: "device"}..."
            )
        )
    }

    override fun onConnected() {
        eventHandler.sendEvent(
            status = ProvisioningEventStreamHandler.STATUS_DISCOVERING,
            data = mapOf(
                "message" to "Connected. Preparing service discovery..."
            )
        )
    }

    override fun onDiscoveringServices() {
        eventHandler.sendEvent(
            status = ProvisioningEventStreamHandler.STATUS_DISCOVERING,
            data = mapOf(
                "message" to "Discovering provisioning services..."
            )
        )
    }

    /**
     * 0x1827 Service、Data In、Data Out、
     * Notificationの準備が完了したときに呼ばれる。
     */
    override fun onReady(mtu: Int) {
        currentMtu =
        (mtu - 3).coerceAtLeast(20)

        val deviceUuid = targetMeshDeviceUuid

        if (deviceUuid == null) {
        handleConnectionError(
            "Mesh Device UUID is not available."
        )
        return
        }

        eventHandler.sendEvent(
            status =
                ProvisioningEventStreamHandler.STATUS_IDENTIFYING,
            data = mapOf(
                "message" to "Identifying device..."
            )
        
        )

        try {
            meshManagerApi.identifyNode(
            deviceUuid,
            ATTENTION_TIMER_SECONDS
            )
        
        } catch (exception: IllegalArgumentException) {
            handleConnectionError(
            "Failed to identify node: " +
                (exception.message ?: "Unknown error")
            )       
        }  
    }

    /**
     * Provisioning Data Out Characteristicから受信した通知。
     */
    override fun onNotificationReceived(data: ByteArray) {
        try {
            meshManagerApi.handleNotifications(
                currentMtu,
                data
            )
        } catch (exception: RuntimeException) {
            Log.e(
                TAG,
                "Failed to process provisioning notification",
                exception
            )

            handleConnectionError(
                "Failed to process provisioning notification: " +
                    (exception.message ?: "Unknown error")
            )
        }
    }

    /**
     * Provisioning Data In Characteristicへの
     * PDU書き込みが完了したときに呼ばれる。
     */
    override fun onWriteCompleted(data: ByteArray) {
        try {
            meshManagerApi.handleWriteCallbacks(
                currentMtu,
                data
            )
        } catch (exception: RuntimeException) {
            Log.e(
                TAG,
                "Failed to process provisioning write callback",
                exception
            )

            handleConnectionError(
                "Failed to process provisioning write: " +
                    (exception.message ?: "Unknown error")
            )
        }
    }

    override fun onDisconnected(message: String?) {
        /*
         * Provisioning完了後または明示的close()による切断は
         * エラーとして扱わない。
         */
        if (!provisioningCompleted && message != null) {
            eventHandler.sendError(message)
        }

        cleanupProvisioningState(
            closeConnection = false
        )
    }

    override fun onError(message: String) {
        handleConnectionError(message)
    }

    // -------------------------------------------------------------------------
    // MeshManagerCallbacks
    // -------------------------------------------------------------------------

    override fun onNetworkLoaded(meshNetwork: MeshNetwork) {
        this.meshNetwork = meshNetwork

        Log.d(
            TAG,
            "Mesh Network loaded: ${meshNetwork.meshName}"
        )
    }

    override fun onNetworkUpdated(meshNetwork: MeshNetwork) {
        this.meshNetwork = meshNetwork

        Log.d(TAG, "Mesh Network updated")
    }

    override fun onNetworkLoadFailed(error: String) {
        Log.w(
            TAG,
            "Mesh Network load failed. Creating a new network: $error"
        )

        /*
         * 保存済みネットワークがない場合、
         * 新しいMesh Networkを作成する。
         *
         * createMeshNetwork()の結果は
         * onNetworkLoaded()へ返される。
         */
        try {
            meshManagerApi.createMeshNetwork()
        } catch (exception: RuntimeException) {
            Log.e(
                TAG,
                "Failed to create Mesh Network",
                exception
            )

            eventHandler.sendError(
                "Failed to create Mesh Network: " +
                    (exception.message ?: error)
            )
        }
    }

    override fun onNetworkImported(meshNetwork: MeshNetwork) {
        this.meshNetwork = meshNetwork

        Log.d(TAG, "Mesh Network imported")
    }

    override fun onNetworkImportFailed(error: String) {
        Log.e(
            TAG,
            "Mesh Network import failed: $error"
        )

        eventHandler.sendError(
            "Failed to import Mesh Network: $error"
        )
    }

    /**
     * Nordic Mesh SDKがProvisioning用PDUを生成したときに呼ばれる。
     */
    override fun sendProvisioningPdu(
        meshNode: UnprovisionedMeshNode,
        pdu: ByteArray
    ) {
        Log.d(
            TAG,
            "Provisioning PDU created: ${pdu.size} bytes"
        )

        provisioningConnection.writeProvisioningPdu(pdu)
    }

    /**
     * 通常のMesh通信PDU生成時に呼ばれる。
     *
     * 現在はProxy接続未実装のため使用しない。
     */
    override fun onMeshPduCreated(pdu: ByteArray) {
        Log.d(
            TAG,
            "Mesh PDU created: ${pdu.size} bytes"
        )
    }

    override fun getMtu(): Int {
        return currentMtu
    }

    // -------------------------------------------------------------------------
    // MeshProvisioningStatusCallbacks
    // -------------------------------------------------------------------------

    override fun onProvisioningStateChanged(
        meshNode: UnprovisionedMeshNode,
        state: ProvisioningState.States,
        data: ByteArray?
    ) {
        Log.d(
            TAG,
            "Provisioning state changed: $state"
        )

        val flutterStatus = when (state) {
            ProvisioningState.States.PROVISIONING_INVITE,
            ProvisioningState.States.PROVISIONING_CAPABILITIES -> {
                ProvisioningEventStreamHandler.STATUS_IDENTIFYING
            }

            else -> {
                ProvisioningEventStreamHandler.STATUS_PROVISIONING
            }
        }

        eventHandler.sendEvent(
            status = flutterStatus,
            data = mapOf(
                "message" to state.name
            )
        )

        /*
         * デバイスのCapabilitiesを受信したら、
         * No OOB方式でProvisioning本体を開始する。
         */
        if (
            state ==
            ProvisioningState.States.PROVISIONING_CAPABILITIES
        ) {
            try {
                meshManagerApi.startProvisioning(meshNode)
            } catch (exception: IllegalArgumentException) {
                Log.e(
                    TAG,
                    "Failed to start provisioning",
                    exception
                )

                handleConnectionError(
                    "Failed to start provisioning: " +
                        (exception.message ?: "Unknown error")
                )
            }
        }
    }

    override fun onProvisioningFailed(
        meshNode: UnprovisionedMeshNode,
        state: ProvisioningState.States,
        data: ByteArray
    ) {
        Log.e(
            TAG,
            "Provisioning failed: $state"
        )

        eventHandler.sendError(
            "Provisioning failed: ${state.name}"
        )

        cleanupProvisioningState(
            closeConnection = true
        )
    }

    override fun onProvisioningCompleted(
        meshNode: ProvisionedMeshNode,
        state: ProvisioningState.States,
        data: ByteArray
    ) {
        provisioningCompleted = true

        Log.d(
            TAG,
            "Provisioning completed. " +
                "unicastAddress=${meshNode.unicastAddress}"
        )

        eventHandler.sendEvent(
            status = ProvisioningEventStreamHandler.STATUS_COMPLETE,
            data = mapOf(
                "message" to "Provisioning complete!",
                "unicastAddress" to meshNode.unicastAddress
            )
        )

        /*
         * Eventを送ってからGATT接続を終了する。
         */
        provisioningConnection.disconnect()
    }

    // -------------------------------------------------------------------------
    // MeshStatusCallbacks
    // -------------------------------------------------------------------------

    override fun onTransactionFailed(
        dst: Int,
        hasIncompleteTimerExpired: Boolean
    ) {
        Log.e(
            TAG,
            "Mesh transaction failed: " +
                "dst=$dst, " +
                "timerExpired=$hasIncompleteTimerExpired"
        )
    }

    override fun onUnknownPduReceived(
        src: Int,
        accessPayload: ByteArray
    ) {
        Log.w(
            TAG,
            "Unknown PDU received from $src"
        )
    }

    override fun onBlockAcknowledgementProcessed(
        dst: Int,
        message: ControlMessage
    ) = Unit

    override fun onBlockAcknowledgementReceived(
        src: Int,
        message: ControlMessage
    ) = Unit

    override fun onHeartbeatMessageReceived(
        src: Int,
        message: ControlMessage
    ) = Unit

    override fun onMeshMessageProcessed(
        dst: Int,
        meshMessage: MeshMessage
    ) = Unit

    override fun onMeshMessageReceived(
        src: Int,
        meshMessage: MeshMessage
    ) = Unit

    override fun onMessageDecryptionFailed(
        meshLayer: String,
        errorMessage: String
    ) {
        Log.e(
            TAG,
            "Message decryption failed: " +
                "layer=$meshLayer, error=$errorMessage"
        )
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private fun handleConnectionError(message: String) {
        Log.e(TAG, message)

        eventHandler.sendError(message)

        cleanupProvisioningState(
            closeConnection = true
        )
    }

    private fun cleanupProvisioningState(
        closeConnection: Boolean
    ) {
        if (closeConnection) {
            provisioningConnection.close()
        }

        targetDevice = null
        targetMeshDeviceUuid = null
        currentMtu = DEFAULT_MTU
        provisioningCompleted = false
    }

    private fun respond(
        result: MethodChannel.Result,
        isSuccess: Boolean,
        message: String
    ) {
        result.success(
            mapOf(
                "isSuccess" to isSuccess,
                "message" to message
            )
        )
    }
}