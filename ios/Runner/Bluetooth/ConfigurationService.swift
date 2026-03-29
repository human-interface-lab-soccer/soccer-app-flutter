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

enum ConfigurationSupportModels: String {
    case genericOnOffModel = "GenericOnOffModel"
    case genericColorModel = "GenericColorModel"
}

class ConfigurationService {

    static let shared = ConfigurationService()
    private let manager = MeshNetworkManager.instance

    private var periodSteps: UInt8 = 0
    private var periodResolution: StepResolution = .hundredsOfMilliseconds
    private var retransmissionCount: UInt8 = 0
    private var retransmissionIntervalSteps: UInt8 = 0
    private var ttl: UInt8 = 0xFF

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
    func configureNode(
        unicastAddress: Address,
        model: ConfigurationSupportModels = .genericOnOffModel
    )
        -> ConfigurationServiceResponse
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
            // Nodeの情報をリクエスト
            try manager.send(ConfigCompositionDataGet(), to: node)

            return ConfigurationServiceResponse(
                isSuccess: true,
                message:
                    "Configuration process started. Awaiting node response..."
            )

        } catch {
            return ConfigurationServiceResponse(
                isSuccess: false,
                message:
                    "Failed to configure the node: \(error.localizedDescription)"
            )
        }
    }

    func setSubscription(withAddress address: Address)
        -> ConfigurationServiceResponse
    {
        var node: Node!
        var serverModel: Model!
        var clientModelID: UInt16?
        var targetGroup: Group?

        // ノードを探す
        do {
            node = try findNode(withUnicastAddress: address)
        } catch {
            return ConfigurationServiceResponse(
                isSuccess: false,
                message: "Couldn't find node"
            )
        }

        // サーバーモデルを探す
        // TODO: .frst ユーザーがモデルを選べるようにする
        let models = node.elements.flatMap({ $0.models })
        //        if let genericOnOffServerModel = models.first(where: {
        //            $0.modelIdentifier == .genericOnOffServerModelId
        //        }) {
        //            serverModel = genericOnOffServerModel
        //            clientModelID = .genericOnOffClientModelId
        //        } else
        if let genericColorServerModel = models.first(where: {
            $0.modelIdentifier == .genericColorServerModelID
        }) {
            serverModel = genericColorServerModel
            clientModelID = .genericColorClientModelID
        } else if let customServerModel = models.first(where: {
            $0.modelIdentifier == .customServerModelID
        }) {
            serverModel = customServerModel
            clientModelID = .customClientModelID
        } else {
            return ConfigurationServiceResponse(
                isSuccess: false,
                message: "Couldn't find server model"
            )
        }

        guard let clientModelID,
            manager.localElements
                .flatMap({ $0.models })
                .first(where: { $0.modelIdentifier == clientModelID }) != nil
        else {
            return ConfigurationServiceResponse(
                isSuccess: false,
                message: "Failed to find client model"
            )
        }

        // LED Groupを探す．存在しない場合は 0xC000 で新規作成
        if let ledGroup = manager.meshNetwork?.groups.first(where: {
            $0.address == MeshAddress(.allLedNodes)
        }) {
            targetGroup = ledGroup
        } else {
            do {
                let ledGroup = try Group(
                    name: "LED Group",
                    address: .allLedNodes
                )
                try manager.meshNetwork?.add(group: ledGroup)
                targetGroup = ledGroup
            } catch {
                return ConfigurationServiceResponse(
                    isSuccess: false,
                    message:
                        "Failed to add group: \(error.localizedDescription)"
                )
            }
        }

        print("----- Subscription -----")
        print("target group: \(String(describing: targetGroup?.address))")
        print("client model id: \(clientModelID)")
        print("server model id: \(serverModel.modelIdentifier)")
        guard let targetGroup else {
            return ConfigurationServiceResponse(
                isSuccess: false,
                message: "Failed to find group"
            )
        }

        /// Subscription メッセージ
        let message: AcknowledgedConfigMessage =
            ConfigModelSubscriptionAdd(group: targetGroup, to: serverModel)
            ?? ConfigModelSubscriptionVirtualAddressAdd(
                group: targetGroup,
                to: serverModel
            )!
        do {
            try MeshNetworkManager.instance.send(message, to: node)
            print("Successfully send subscription message")
        } catch {
            return ConfigurationServiceResponse(
                isSuccess: false,
                message: "Failed to add group"
            )
        }

        return ConfigurationServiceResponse(
            isSuccess: true,
            message: "Start subscription ..."
        )
    }

    func setPublication(withAddress address: Address)
        -> ConfigurationServiceResponse
    {
        var node: Node!
        var serverModel: Model!
        var clientModelID: UInt16?

        // ノードを探す
        do {
            node = try findNode(withUnicastAddress: address)
        } catch {
            return ConfigurationServiceResponse(
                isSuccess: false,
                message: "Couldn't find node"
            )
        }

        // サーバーモデルを探す
        let models = node.elements.flatMap({ $0.models })
        if let genericOnOffServerModel = models.first(where: {
            $0.modelIdentifier == .genericOnOffServerModelId
        }) {
            serverModel = genericOnOffServerModel
            clientModelID = .genericOnOffClientModelId
        } else if let genericColorServerModel = models.first(where: {
            $0.modelIdentifier == .genericColorServerModelID
        }) {
            serverModel = genericColorServerModel
            clientModelID = .genericColorClientModelID
        } else {
            return ConfigurationServiceResponse(
                isSuccess: false,
                message: "Couldn't find server model"
            )
        }

        guard let clientModelID,
            let clientModel = manager.localElements.flatMap({ $0.models })
                .first(where: { $0.modelIdentifier == clientModelID })
        else {
            return ConfigurationServiceResponse(
                isSuccess: false,
                message: "Failed to find client model"
            )
        }

        // groupを探す
        let network = MeshNetworkManager.instance.meshNetwork!
        guard
            let targetGroup = network.groups
                .first(where: { $0.address == MeshAddress(.allLedNodes) })
        else {
            return ConfigurationServiceResponse(
                isSuccess: false,
                message: "Group not found"
            )
        }
        print("----- Publication -----")
        print("target group: \(targetGroup.address)")
        print("client model id: \(clientModelID)")
        print("server model id: \(serverModel.modelIdentifier)")

        guard let applicationKey = clientModel.boundApplicationKeys.first else {
            return ConfigurationServiceResponse(
                isSuccess: false,
                message: "ApplicationKey not found"
            )
        }

        let publish = Publish(
            to: targetGroup.address,
            using: applicationKey,
            usingFriendshipMaterial: false,
            ttl: ttl,
            period: Publish.Period(
                steps: periodSteps,
                resolution: periodResolution
            ),
            retransmit: Publish.Retransmit(
                publishRetransmitCount: retransmissionCount,
                intervalSteps: retransmissionIntervalSteps
            )
        )
        let publicationMessage: AcknowledgedConfigMessage =
            ConfigModelPublicationSet(publish, to: serverModel)
            ?? ConfigModelPublicationVirtualAddressSet(
                publish,
                to: serverModel
            )!
        do {
            try MeshNetworkManager.instance.send(
                publicationMessage,
                to: node,
                withTtl: UInt8(3)
            )
            print("Successfully send publication message!")
        } catch {
            return ConfigurationServiceResponse(
                isSuccess: false,
                message: "Failed to send message"
            )
        }

        return ConfigurationServiceResponse(
            isSuccess: true,
            message: "start publication ..."
        )
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
