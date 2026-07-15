package jp.ac.saitama_u.mech.human.soccerAppFlutter.flutterchannels

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import jp.ac.saitama_u.mech.human.soccerAppFlutter.bluetooth.GeneralBleScanner
import jp.ac.saitama_u.mech.human.soccerAppFlutter.bluetooth.ProvisioningService

class FlutterChannelManager(
    private val messenger: BinaryMessenger,
    private val bleScanner: GeneralBleScanner,
    private val provisioningService: ProvisioningService,
    private val provisioningEventStreamHandler:
        ProvisioningEventStreamHandler
) {

    companion object {
        private const val DOMAIN =
            "human.mech.saitama-u.ac.jp"

        private const val SCANNER_METHOD_CHANNEL =
            "$DOMAIN/scannerMethodChannel"

        private const val SCANNER_EVENT_CHANNEL =
            "$DOMAIN/scannerEventChannel"

        private const val PROVISIONING_METHOD_CHANNEL =
            "$DOMAIN/provisioningMethodChannel"

        private const val PROVISIONING_EVENT_CHANNEL =
            "$DOMAIN/provisioningEventChannel"
    }

    fun setupChannels() {
        setupScannerMethodChannel()
        setupProvisioningMethodChannel()
        setupScannerEventChannel()
        setupProvisioningEventChannel()
    }

    private fun setupScannerMethodChannel() {
        MethodChannel(
            messenger,
            SCANNER_METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "startScanning" -> {
                    bleScanner.startScan()
                    result.success("Started Scan...")
                }

                "stopScanning" -> {
                    bleScanner.stopScan()
                    result.success("Stopped Scan.")
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun setupProvisioningMethodChannel() {
        MethodChannel(
            messenger,
            PROVISIONING_METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "provisioning" -> {
                    val deviceId =
                        call.argument<String>("uuid")

                    if (deviceId == null) {
                        result.success(
                            mapOf(
                                "isSuccess" to false,
                                "message" to
                                    "UUID key not found in arguments."
                            )
                        )
                        return@setMethodCallHandler
                    }

                    provisioningService.startProvisioningProcess(
                        deviceId = deviceId,
                        result = result
                    )
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun setupScannerEventChannel() {
        EventChannel(
            messenger,
            SCANNER_EVENT_CHANNEL
        ).setStreamHandler(bleScanner)
    }

    private fun setupProvisioningEventChannel() {
        EventChannel(
            messenger,
            PROVISIONING_EVENT_CHANNEL
        ).setStreamHandler(
            provisioningEventStreamHandler
        )
    }
}