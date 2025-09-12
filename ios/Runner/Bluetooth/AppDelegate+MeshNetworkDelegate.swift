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
            print("Couldn't find node.")
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
            handleModelAppStatus(
                modelAppStatus: modelStatus,
                manager: manager,
                node: node
            )

        default:
            print("Message type : \(type(of: message))")
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
            print(
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
        let serverModelName = "Generic OnOff Server"
        // AppKeyとGeneric OnOff Serverモデルを見つける
        guard
            let appKey = manager.meshNetwork?.applicationKeys.first(where: {
                node.knows(networkKey: $0.boundNetworkKey)
            }),
            let genericOnOffServerModel = node.elements
                .flatMap({ $0.models })
                .first(where: { $0.name == serverModelName })
        else {
            print("AppKey or 'Generic OnOff Server' model not found")
            return
        }

        bindModel(
            model: genericOnOffServerModel,
            appKey: appKey,
            manager: manager,
            node: node
        )
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
    ) {
        if modelAppStatus.status == .success {
            print("Model bind successful!")
            // Configuration完了後に色を変える場合は，ここに処理を追加
            // ex. manager.send(message, from: clientModel, to: serverModel)

        } else {
            print("Model bind failed with status: \(modelAppStatus.status)")
        }
    }
}
