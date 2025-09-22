//
//  MeshNetworkService.swift
//  Runner
//
//  Created by naokeyn on 2025/09/22.
//

import Foundation
import NordicMesh

class MeshNetworkServiceResponse {
    let isSuccess: Bool
    let message: String?

    init(isSuccess: Bool, message: String?) {
        self.isSuccess = isSuccess
        self.message = message
    }
}

enum MeshNetworkServiceError: Error {
    // TODO: いい感じにして
    case nodeNotFound

}

class MeshNetworkService {

    // シングルトンにする
    static let shared = MeshNetworkService()

    private let manager = MeshNetworkManager.instance

    // コンストラクタをプライベートに設定
    private init() {}

    /// GATT Bearer 経由でLEDのOnOffを行うメッセージを送信するメソッド
    ///  - GATT Bearer経由でのみ動作することに注意してください
    /// - ConfigrationによりApplication Keyのバインドが行われていない場合はメッセージの送信が行えません
    ///
    /// - Parameters:
    ///     - unicastAddress: ノードのユニキャストアドレス
    ///     - state: LEDの状態（trueで点灯，false で消灯）
    /// - Returns:
    ///     - MeshNetworkServiceResponse
    ///         - isSuccess (Bool): メッセージ送信の成否
    ///         - message (String?): エラーメッセージ
    ///

    func setGenericOnOffState(unicastAddress: Address, state: Bool)
        -> MeshNetworkServiceResponse
    {
        var node: Node?
        // ノードを探す
        do {
            node = try findNode(withUnicastAddress: unicastAddress)
        } catch {
            print("Failed to find node")
            return MeshNetworkServiceResponse(
                isSuccess: false,
                message: "Failed to find node."
            )
        }

        // clientモデルを探す
        guard
            let clientModel = manager.localElements
                .flatMap({ $0.models })
                .first(where: {
                    $0.modelIdentifier == .genericOnOffClientModelId
                })
        else {
            return MeshNetworkServiceResponse(
                isSuccess: false,
                message: "Couldn't find Client-Model"
            )
        }

        // Serverモデルを探す
        guard let node,
            let serverModel = node.elements
                .flatMap({ $0.models })
                .first(where: {
                    $0.modelIdentifier == .genericOnOffServerModelId
                })
        else {
            return MeshNetworkServiceResponse(
                isSuccess: false,
                message: "Couldn't find Server-Model"
            )
        }

        // メッセージを作成
        let message = GenericOnOffSet(state)
        Task {
            let result = try await manager.send(
                message,
                from: clientModel,
                to: serverModel
            )
            print(result)
        }
        return MeshNetworkServiceResponse(
            isSuccess: true,
            message: "Successfully start!"
        )
    }

    private func findNode(withUnicastAddress unicastAddress: Address) throws
        -> Node
    {
        guard let node = manager.meshNetwork?.node(withAddress: unicastAddress)
        else {
            throw MeshNetworkServiceError.nodeNotFound
        }
        return node
    }
}
