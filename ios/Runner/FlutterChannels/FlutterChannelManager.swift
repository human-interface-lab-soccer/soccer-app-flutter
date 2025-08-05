//
//  FlutterChannelManager.swift
//  Runner
//
//  Created by naokeyn on 2025/07/28.
//

import CoreBluetooth
import Flutter
import NordicMesh

enum ChannelName {
    static let scannerMethod = "human.mech.saitama-u.ac.jp/scannerMethodChannel"
    static let scannerEvent = "human.mech.saitama-u.ac.jp/scannerEventChannel"
    static let provisioningMethod =
        "human.mech.saitama-u.ac.jp/provisioningMethodChannel"
    static let provisioningEvent =
        "human.mech.saitama-u.ac.jp/provisioningEventChannel"
}

class FlutterChannelManager {
    private let messenger: FlutterBinaryMessenger
    private weak var bleScanner: GeneralBleScanner?
    private weak var provisioningService: ProvisioningService?

    private var scannerMethodChannel: FlutterMethodChannel!
    private var provisioningMethodChannel: FlutterMethodChannel!
    private var scannerEventChannel: FlutterEventChannel!
    private var provisioningEventChannel: FlutterEventChannel!

    init(
        messenger: FlutterBinaryMessenger,
        bleScanner: GeneralBleScanner,
        provisioningService: ProvisioningService
    ) {
        self.messenger = messenger
        self.bleScanner = bleScanner
        self.provisioningService = provisioningService
    }

    func setupChannels() {
        setupMethodChannels()
        setupEventChannels()
    }

    private func setupMethodChannels() {
        scannerMethodChannel = FlutterMethodChannel(
            name: ChannelName.scannerMethod,
            binaryMessenger: messenger
        )
        provisioningMethodChannel = FlutterMethodChannel(
            name: ChannelName.provisioningMethod,
            binaryMessenger: messenger
        )

        scannerMethodChannel.setMethodCallHandler {
            [weak self] (call, result) in
            self?.handleScannerMethod(call: call, result: result)
        }

        provisioningMethodChannel.setMethodCallHandler {
            [weak self] (call, result) in
            self?.handleProvisioningMethod(call: call, result: result)
        }
    }

    private func setupEventChannels() {
        scannerEventChannel = FlutterEventChannel(
            name: ChannelName.scannerEvent,
            binaryMessenger: messenger
        )

        provisioningEventChannel = FlutterEventChannel(
            name: ChannelName.provisioningEvent,
            binaryMessenger: messenger
        )
        provisioningEventChannel.setStreamHandler(
            provisioningService?.provisioningEventStreamHandlerInstance
        )
        scannerEventChannel.setStreamHandler(bleScanner)
    }

    private func handleScannerMethod(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch call.method {
        case "startScanning":
            bleScanner?.startScan()
            result("Started Scan...")
        case "stopScanning":
            bleScanner?.stopScan()
            result("Stopped Scan.")
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleProvisioningMethod(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch call.method {
        case "provisioning":
            guard let args = call.arguments as? [String: String],
                let uuidString = args["uuid"]
            else {
                result([
                    "isSuccess": false,
                    "body": "UUID key not found in arguments.",
                ])
                return
            }
            provisioningService?.startProvisioningProcess(
                for: uuidString,
                result: result
            )
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
