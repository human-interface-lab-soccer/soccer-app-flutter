//
//  ConfigurationService.swift
//  Runner
//
//  Created by naokeyn on 2025/08/28.
//
import NordicMesh

enum ConfigurationServiceError: Error {
    case nodeNotFound
}

class ConfigurationServiceResponse {
    let isSuccess: Bool
    let message: String

    init(isSuccess: Bool, message: String) {
        self.isSuccess = isSuccess
        self.message = message
    }
}

class ConfigurationService {

    static let shared = ConfigurationService()

    private let manager = MeshNetworkManager.instance

    private init() {}
    /// MeshNetwork内のノードをリセットするメソッド
    /// - Parameters:
    ///     - unicastAddress): ノードのユニキャストアドレス
    ///
    func resetNode(unicastAddress: Address) -> ConfigurationServiceResponse {
        do {
            let node = try findNode(withUnicastAddress: unicastAddress)
            let message = ConfigNodeReset()
            try manager.send(message, to: node)
            return ConfigurationServiceResponse(
                isSuccess: true,
                message: "Successfully reset the node!"
            )
        } catch {
            return ConfigurationServiceResponse(
                isSuccess: false,
                message:
                    "Failed to reset the node: \(error.localizedDescription)"
            )
        }
    }

    /// Provisioning済みのノードをConfigurationするメソッド
    /// - Parameters:
    ///     - unicastAddress: ノードのユニキャストアドレス
    ///
    func configureNode(unicastAddress: Address) -> ConfigurationServiceResponse
    {
        do {
            let node = try findNode(withUnicastAddress: unicastAddress)

            // AppKeyの取得，無ければ生成
            var applicationKey: ApplicationKey?
            if let availableKeys = manager.meshNetwork?.applicationKeys
                .notKnownTo(node: node), !availableKeys.isEmpty
            {
                let keys = availableKeys.filter {
                    node.knows(networkKey: $0.boundNetworkKey)
                }
                if !keys.isEmpty {
                    applicationKey = keys[0]
                }
            }

            if applicationKey == nil {
                // applicationKeyを新しく生成
                applicationKey = try manager.meshNetwork?.add(
                    applicationKey: Data.random128BitKey(),
                    name: "Main Application Key"
                )
            }

            guard let selectedAppKey = applicationKey else {
                return ConfigurationServiceResponse(
                    isSuccess: false,
                    message: "No ApplicationKey available"
                )
            }

            // AppKeyの追加
            try manager.send(
                ConfigAppKeyAdd(applicationKey: selectedAppKey),
                to: node
            )

            // AppKeyのバインド（次のPRでやります）

            // FIXME: モックのため，仮でメッセージを設定しています．
            return ConfigurationServiceResponse(
                isSuccess: true,
                message: "This is a mock response for `configureNode`"
            )
        } catch {
            return ConfigurationServiceResponse(
                isSuccess: false,
                message:
                    "Failed to configure the node: \(error.localizedDescription)"
            )
        }
    }

    private func findNode(withUnicastAddress unicastAddress: Address) throws
        -> Node
    {
        guard let node = manager.meshNetwork?.node(withAddress: unicastAddress)
        else {
            throw ConfigurationServiceError.nodeNotFound
        }
        return node
    }
}
