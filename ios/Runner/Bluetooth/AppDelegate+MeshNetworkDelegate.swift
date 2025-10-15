//
//  AppDelegate+MeshNetworkDelegate.swift
//  Runner
//
//  Created by naokeyn on 2025/09/12.
//

import Foundation
import NordicMesh

extension AppDelegate: MeshNetworkDelegate {

    func meshNetworkManager(
        _ manager: NordicMesh.MeshNetworkManager,
        didReceiveMessage message: any NordicMesh.MeshMessage,
        sentFrom source: NordicMesh.Address,
        to destination: NordicMesh.MeshAddress
    ) {
        // nodeを探す
        guard let node = manager.meshNetwork?.node(withAddress: source) else {
            print("Couldn't fild node with address \(source)")
            return
        }

        switch message {
        case is ConfigCompositionDataStatus:
            print("Received Composition Data from \(source)")
            // タイマーを停止
            compositionDataTimer?.invalidate()
            compositionDataTimer = nil
            // 構成データ取得後、モデルバインドに進む
            handleCompositionDataStatus(
                node: node,
                manager: manager
            )

        case let appKeyStatus as ConfigAppKeyStatus:
            print("Received AppKeyStatus: \(appKeyStatus.status)")
            handleAppKeyStatus(
                appKeyStatus: appKeyStatus,
                manager: manager,
                node: node
            )

        case let modelStatus as ConfigModelAppStatus:
            print("Recieved ConfigModelAppStatus: \(modelStatus.status)")
            Task {
                await handleModelAppStatus(
                    modelAppStatus: modelStatus,
                    manager: manager,
                    node: node
                )
            }

        case let configSubscriptionState as ConfigModelSubscriptionStatus:
            if configSubscriptionState.isSuccess {
                sendFlutterEvent(
                    status: .success,
                    message: "Successfully subscribe model"
                )
            } else {
                sendFlutterEvent(
                    status: .error,
                    message:
                        "Failed to subscribe model: \(configSubscriptionState.message)"
                )
            }

        case let configPublicaitionStatus as ConfigModelPublicationStatus:
            if configPublicaitionStatus.status == .success {
                sendFlutterEvent(
                    status: .success,
                    message: "Successfully publish model"
                )
            } else {
                sendFlutterEvent(
                    status: .error,
                    message:
                        "Failed to publish model: \(configPublicaitionStatus.message)"
                )
            }

        default:
            print("Message type : \(type(of: message))")
            print(message)
        }
    }

    private func handleAppKeyStatus(
        appKeyStatus: ConfigAppKeyStatus,
        manager: MeshNetworkManager,
        node: Node
    ) {
        if appKeyStatus.status == .success {
            print("AppKey added successfully.")
            // AppKeyの追加成功後，Composition Dataをリクエスト
            sendCompositionDataRequest(to: node)
        } else {
            sendFlutterEvent(
                status: .error,
                message:
                    "Failed to add AppKey: \(appKeyStatus.status.debugDescription)"
            )
        }
    }

    // ConfigCompositionDataGet を送信するリトライロジック
    private func sendCompositionDataRequest(to node: Node) {
        // すでにタイマーが動いていれば何もしない
        guard compositionDataTimer == nil else { return }

        // リトライカウントをリセット
        compositionDataRetries = 0

        // 最初のメッセージを送信
        sendCompositionDataMessage(to: node)

        // タイマーを開始
        compositionDataTimer = Timer.scheduledTimer(
            withTimeInterval: retryTimeInterval,
            repeats: true
        ) { [weak self] _ in
            guard let self = self else { return }

            self.compositionDataRetries += 1
            print(
                "Composition Data Get timeout. Retry \(self.compositionDataRetries)/\(self.maxCompositionDataRetries)..."
            )

            if self.compositionDataRetries <= self.maxCompositionDataRetries {
                self.sendCompositionDataMessage(to: node)
            } else {
                self.compositionDataTimer?.invalidate()
                self.compositionDataTimer = nil
                print(
                    "Failed to get Composition Data after \(self.maxCompositionDataRetries) retries."
                )
            }
        }
    }

    // 実際に ConfigCompositionDataGet を送信するヘルパーメソッド
    private func sendCompositionDataMessage(to node: Node) {
        do {
            try meshNetworkManager.send(ConfigCompositionDataGet(), to: node)
            print(
                "Sent ConfigCompositionDataGet to \(node.name ?? "Unknown Node")"
            )
        } catch {
            print(
                "Failed to send ConfigCompositionDataGet: \(error.localizedDescription)"
            )
        }
    }

    private func handleCompositionDataStatus(
        node: Node,
        manager: MeshNetworkManager
    ) {
        let clientUnicastAddress = Address(0x0001)
        var serverModel: Model?
        var clientModelID: UInt16?

        // elementとmodelを書き出す
        let models = node.elements.flatMap({ $0.models })

        // GenericOnOffServerがいるとき
        if let genericOnOffServerModel = models.first(where: {
            UInt16($0.modelId) == .genericOnOffServerModelId
        }) {
            serverModel = genericOnOffServerModel
            clientModelID = .genericOnOffClientModelId
        }
        // GenericColorServerがいるとき
        else if let genericColorServerModel = models.first(where: {
            UInt16($0.modelId) == .genericColorServerModelID
        }) {
            serverModel = genericColorServerModel
            clientModelID = .genericColorClientModelID
        }
        // Configuration可能なサーバーが見つからないとき
        else {
            sendFlutterEvent(
                status: .error,
                message: "Valid server model not found"
            )
            return
        }
        // AppKeyとGeneric OnOff Serverモデルを見つける
        guard
            let appKey = manager.meshNetwork?.applicationKeys.first(where: {
                node.knows(networkKey: $0.boundNetworkKey)
            }), let serverModel
        else {
            print("AppKey or server model not found")
            return
        }

        bindModel(
            model: serverModel,
            appKey: appKey,
            manager: manager,
            node: node
        )

        // localElementから対応するモデルを見つける
        guard
            let clientModel = manager.localElements
                .flatMap({ $0.models })
                .first(where: {
                    $0.modelIdentifier == clientModelID
                })
        else {
            print("Failed to find client model.")
            return
        }
        do {
            guard
                let clientBindMessage = ConfigModelAppBind(
                    applicationKey: appKey,
                    to: clientModel
                )
            else {
                print("Failed to create client-model-bind message")
                return
            }
            try manager.send(clientBindMessage, to: clientUnicastAddress)

        } catch {
            print("Failed to bind Client Model")
            print("\(error.localizedDescription)")
            return
        }
        print("Successfully bind client model")
    }

    private func bindModel(
        model: Model,
        appKey: ApplicationKey,
        manager: MeshNetworkManager,
        node: Node
    ) {
        guard
            let bindMessage = ConfigModelAppBind(
                applicationKey: appKey,
                to: model
            )
        else {
            print("Message Create Error")
            return
        }
        do {
            try manager.send(bindMessage, to: node)
            print("Sent ConfigModelAppBind to \(model.name ?? "Unknown Model")")
        } catch {
            print(
                "Failed to bind AppKey to model: \(error.localizedDescription)"
            )
        }
    }

    private func handleModelAppStatus(
        modelAppStatus: ConfigModelAppStatus,
        manager: MeshNetworkManager,
        node: Node
    ) async {
        if modelAppStatus.status == .success {
            sendFlutterEvent(
                status: .success,
                message: "Successfully bind AppKey to Model"
            )
            guard
                (manager.meshNetwork?.applicationKeys.first(where: {
                    node.knows(networkKey: $0.boundNetworkKey)
                })) != nil
            else {
                print("Failed to get app key")
                return
            }
        } else {
            sendFlutterEvent(
                status: .error,
                message:
                    "Model bind failed with status: \(modelAppStatus.status)"
            )
        }
    }

    private func setColor(
        _ manager: MeshNetworkManager,
        node: Node,
        appKey: ApplicationKey
    ) async {
        guard
            let clientModel = manager.localElements
                .flatMap({ $0.models })
                .first(where: {
                    $0.modelIdentifier == .genericOnOffClientModelId
                })
        else {
            print("Failed to find Client Model")
            return

        }
        guard
            let serverModel = node.elements
                .flatMap({ $0.models })
                .first(where: {
                    $0.modelIdentifier == .genericOnOffServerModelId
                })
        else {
            print("Failed to find Server model.")
            sendFlutterEvent(
                status: .error,
                message: "Failed to find models"
            )
            return
        }

        let message = GenericOnOffSet(true)

        do {
            let result = try await manager.send(
                message,
                from: clientModel,
                to: serverModel,
                withTtl: UInt8(5),
                using: appKey
            )
            print(result)
            sendFlutterEvent(
                status: .success,
                message: "Successfully sent message"
            )
        } catch {
            sendFlutterEvent(
                status: .error,
                message:
                    "Failed to send message: \(error.localizedDescription)"
            )
        }
    }

    private func sendFlutterEvent(status: MeshNetworkStatus, message: String?) {
        MeshNetworkEventStreamHandler.shared.sendEvent(
            status: status,
            data: ["message": message ?? "No message"]
        )
    }
}
