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
        var groups: [Group]!
        var specialGroups: [Group]!
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
            let clientModel = manager.localElements
                .flatMap({ $0.models })
                .first(where: { $0.modelIdentifier == clientModelID })
        else {
            return ConfigurationServiceResponse(
                isSuccess: false,
                message: "Failed to find client model"
            )
        }

        // groupを探す
        let network = MeshNetworkManager.instance.meshNetwork!
        let alreadySubscribedGroups = serverModel.subscriptions
        groups = network.groups
            .filter { !alreadySubscribedGroups.contains($0) }
        specialGroups = Group.specialGroups
            .filter { $0 != .allNodes }
            .filter { !alreadySubscribedGroups.contains($0) }

        // groupが無ければ生成
        if groups.isEmpty {
            guard
                let groupAddress = manager.meshNetwork?
                    .nextAvailableGroupAddress()
            else {
                return ConfigurationServiceResponse(
                    isSuccess: false,
                    message: "failed to create group"
                )
            }
            do {
                let newGroup = try Group(
                    name: "LED Group",
                    address: groupAddress
                )
                try manager.meshNetwork?.add(group: newGroup)
                targetGroup = newGroup
            } catch {
                return ConfigurationServiceResponse(
                    isSuccess: false,
                    message:
                        "Failed to add group: \(error.localizedDescription)"
                )
            }
        } else {
            targetGroup = groups.first
        }

        print("target group: \(targetGroup?.address)")
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
            message: "mock Message"
        )
    }

    func setPublication(withAddress address: Address)
        -> ConfigurationServiceResponse
    {
        var node: Node!
        var serverModel: Model!
        var clientModelID: UInt16!
        var groups: [Group]!
        var specialGroups: [Group]!
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
        let alreadySubscribedGroups = serverModel.subscriptions
        groups = network.groups
            .filter { !alreadySubscribedGroups.contains($0) }
        specialGroups = Group.specialGroups
            .filter { $0 != .allNodes }
            .filter { !alreadySubscribedGroups.contains($0) }

        targetGroup = serverModel.subscriptions.first
        guard let targetGroup else {
            return ConfigurationServiceResponse(
                isSuccess: false,
                message: "Group not found"
            )
        }
        print("target group: \(targetGroup.address)")

        let applicationKey = clientModel.boundApplicationKeys.first!

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
            print("Soccessfully send publication message!")
        } catch {
            return ConfigurationServiceResponse(
                isSuccess: false,
                message: "Failed to send message"
            )
        }

        return ConfigurationServiceResponse(
            isSuccess: true,
            message: "mock Message"
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
