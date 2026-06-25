package jp.ac.saitama_u.mech.human.soccerAppFlutter.flutterchannels

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import jp.ac.saitama_u.mech.human.soccerAppFlutter.bluetooth.GeneralBleScanner

class FlutterChannelManager(
    private val messenger: BinaryMessenger,
    private val bleScanner: GeneralBleScanner
) {
    companion object {
        private const val DOMAIN = "human.mech.saitama-u.ac.jp"
        private const val SCANNER_METHOD_CHANNEL = "$DOMAIN/scannerMethodChannel"
        private const val SCANNER_EVENT_CHANNEL = "$DOMAIN/scannerEventChannel"
    }

    fun setupChannels() {
        setupMethodChannels()
        setupEventChannels()
    }

    private fun setupMethodChannels() {
        MethodChannel(messenger, SCANNER_METHOD_CHANNEL).setMethodCallHandler { call, result ->
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

    private fun setupEventChannels() {
        EventChannel(messenger, SCANNER_EVENT_CHANNEL).setStreamHandler(bleScanner)
    }
}