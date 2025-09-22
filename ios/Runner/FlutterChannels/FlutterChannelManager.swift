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
    static let domain = "human.mech.saitama-u.ac.jp"
    static let scannerMethod = "\(domain)/scannerMethodChannel"
    static let scannerEvent = "\(domain)/scannerEventChannel"
    static let provisioningMethod = "\(domain)/provisioningMethodChannel"
    static let provisioningEvent = "\(domain)/provisioningEventChannel"
    static let meshNetworkMethod = "\(domain)/meshNetworkMethodChannel"
    static let meshNetworkEvent = "\(domain)/meshNetworkEventChannel"
}

class FlutterChannelManager {
    private let messenger: FlutterBinaryMessenger
    private weak var bleScanner: GeneralBleScanner?
    private weak var provisioningService: ProvisioningService?

    private var scannerMethodChannel: FlutterMethodChannel!
    private var scannerEventChannel: FlutterEventChannel!
    private var provisioningMethodChannel: FlutterMethodChannel!
    private var provisioningEventChannel: FlutterEventChannel!
    private var meshNetworkMethodChannel: FlutterMethodChannel!
    private var meshNetworkEventChannel: FlutterEventChannel!

    init(
        messenger: FlutterBinaryMessenger,
        bleScanner: GeneralBleScanner,
        provisioningService: ProvisioningService,
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

        meshNetworkMethodChannel = FlutterMethodChannel(
            name: ChannelName.meshNetworkMethod,
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

        meshNetworkMethodChannel.setMethodCallHandler {
            [weak self] (call, result) in
            self?.handleMeshNetworkMethod(call: call, result: result)
        }
    }

    private func setupEventChannels() {
        scannerEventChannel = FlutterEventChannel(
            name: ChannelName.scannerEvent,
            binaryMessenger: messenger
        )
        scannerEventChannel.setStreamHandler(bleScanner)

        provisioningEventChannel = FlutterEventChannel(
            name: ChannelName.provisioningEvent,
            binaryMessenger: messenger
        )
        provisioningEventChannel.setStreamHandler(
            provisioningService?.provisioningEventStreamHandlerInstance
        )

        meshNetworkEventChannel = FlutterEventChannel(
            name: ChannelName.meshNetworkEvent,
            binaryMessenger: messenger
        )
        meshNetworkEventChannel.setStreamHandler(
            MeshNetworkEventStreamHandler.shared
        )
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
                handleMethodResponse(
                    result: result,
                    isSuccess: false,
                    message: "UUID key not found in arguments."
                )
                return
            }
            provisioningService?.startProvisioningProcess(
                for: uuidString,
                result: result
            )
        case "resetNode":
            // パラメータに `unicastAddress` が含まれているかを確認
            guard let args = call.arguments as? [String: Any],
                let unicastAddress = args["unicastAddress"]
            else {
                handleMethodResponse(
                    result: result,
                    isSuccess: false,
                    message: "unicastAddress not found in arguments."
                )
                return
            }
            let response = ConfigurationService.shared.resetNode(
                unicastAddress: unicastAddress as! Address
            )
            handleMethodResponse(
                result: result,
                isSuccess: response.isSuccess,
                message: response.message
            )

        case "configureNode":
            // パラメータに `unicastAddress` が含まれているかを確認
            guard let args = call.arguments as? [String: Any],
                let unicastAddress = args["unicastAddress"]
            else {
                handleMethodResponse(
                    result: result,
                    isSuccess: false,
                    message: "unicastAddress not found in arguments."
                )
                return
            }

            let response = ConfigurationService.shared.configureNode(
                unicastAddress: unicastAddress as! Address
            )
            handleMethodResponse(
                result: result,
                isSuccess: response.isSuccess,
                message: response.message
            )

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleMeshNetworkMethod(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch call.method {
        case "getNodeList":
            guard let nodeList = MeshNetworkManager.instance.meshNetwork?.nodes
            else {
                result([])
                return
            }
            let returnList: [[String: String]] = nodeList.map { node in
                return [
                    "name": node.name ?? "unknown device",
                    "uuid": "\(node.uuid)",
                    "primaryUnicastAddress": "\(node.primaryUnicastAddress)",
                ]
            }
            print(returnList)
            result(returnList)

        case "genericOnOffSet":
            // パラメータに `unicastAddress`, `state` が含まれているかを確認
            guard let args = call.arguments as? [String: Any],
                let unicastAddress = args["unicastAddress"] as? Address,
                let state = args["state"] as? Bool
            else {
                handleMethodResponse(
                    result: result,
                    isSuccess: false,
                    message: "unicastAddress or state not found"
                )
                return
            }

            let response = MeshNetworkService.shared.setGenericOnOffState(
                unicastAddress: unicastAddress,
                state: state
            )
            handleMethodResponse(
                result: result,
                isSuccess: response.isSuccess,
                message: response.message ?? "No message provided"
            )
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// メソッド呼び出しの結果を，成功/失敗のステータスとメッセージを含めてFlutter側に返す
    /// - Parameters:
    ///     - result: FlutterResult
    ///     - isSuccess: 処理が成功したかどうかを示す真偽値
    ///     - message: 処理結果の詳細な情報を含む文字列
    ///
    /// この関数は，プラットフォームチャンネルを介した非同期処理の完了をFlutterに通知するために使用される
    /// 戻り値はMap形式で，Flutter側の`MethodChannel.invokeMethod`の`result`引数に渡される
    ///
    private func handleMethodResponse(
        result: @escaping FlutterResult,
        isSuccess: Bool,
        message: String
    ) {
        result(["isSuccess": isSuccess, "message": message])
    }
}
