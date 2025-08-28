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

        //            // Unicast Address からノードを指定
        //            let manager = MeshNetworkManager.instance
        //            guard
        //                let node = manager.meshNetwork?.node(
        //                    withAddress: unicastAddress as! Address
        //                )
        //            else {
        //                handleMethodResponse(
        //                    result: result,
        //                    isSuccess: false,
        //                    message:
        //                        "Couldn't identify the node wit address \(unicastAddress)."
        //                )
        //                return
        //            }
        //
        //            // ノードをProvisioning前の状態にリセット
        //            let message = ConfigNodeReset()
        //            do {
        //                try manager.send(message, to: node)
        //                handleMethodResponse(
        //                    result: result,
        //                    isSuccess: true,
        //                    message: "Successfully reset the node!"
        //                )
        //            } catch {
        //                handleMethodResponse(
        //                    result: result,
        //                    isSuccess: false,
        //                    message:
        //                        "Failed to reset the node. \(error.localizedDescription)"
        //                )
        //            }

        // TODO: ロジックを別のclassなりに書き出す！！
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

//            // unicast Address からノードを指定
//            // TODO: 上記の `resetNode` と処理が重複しているため，まとめたい
//            let manager = MeshNetworkManager.instance
//            guard
//                let node = manager.meshNetwork?.node(
//                    withAddress: unicastAddress as! Address
//                )
//            else {
//                handleMethodResponse(
//                    result: result,
//                    isSuccess: false,
//                    message: "Couldn't identify the node."
//                )
//                return
//            }
//
//            // ApplicationKey の取得．無ければ生成する
//            var applicationKey: ApplicationKey?
//            if let availableKeys = manager.meshNetwork?.applicationKeys
//                .notKnownTo(node: node), !availableKeys.isEmpty
//            {
//                let keys = availableKeys.filter {
//                    node.knows(networkKey: $0.boundNetworkKey)
//                }
//                if !keys.isEmpty {
//                    applicationKey = keys[0]
//                }
//            }
//
//            if applicationKey == nil {
//                // applicationKeyを新しく生成
//                do {
//                    applicationKey = try manager.meshNetwork?.add(
//                        applicationKey: Data.random128BitKey(),
//                        name: "Main Application Key"
//                    )
//                } catch {
//                    handleMethodResponse(
//                        result: result,
//                        isSuccess: false,
//                        message:
//                            "Failed to add new ApplicationKey: \(error.localizedDescription)"
//                    )
//                    return
//                }
//            }
//
//            guard let selectedAppKey = applicationKey else {
//                handleMethodResponse(
//                    result: result,
//                    isSuccess: false,
//                    message: "No ApplicationKey available"
//                )
//                return
//            }
//            // ノードにApplicationKey を追加
//            do {
//                try manager.send(
//                    ConfigAppKeyAdd(applicationKey: selectedAppKey),
//                    to: node
//                )
//                print("Successfully added AppKey to node")
//            } catch {
//                print("Faild to Add AppKey: \(error.localizedDescription)")
//            }
//
//            // モデルに ApplicationKey をバインド（次のPRでやります）
//
//            // FIXME: mockなのでテキトーなメッセージを返してます（バインドまで終わったら考えます）
//            handleMethodResponse(
//                result: result,
//                isSuccess: true,
//                message: "This is a mock response for `configureNode."
//            )

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
