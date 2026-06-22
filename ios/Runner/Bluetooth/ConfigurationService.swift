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

    var isConfiguring = false
    var isSubscribed = false
    var isPublished = false
    var currentTargetAddress: Address?

    // Watchdog, Trace and ACK properties
    var configTraceId: UUID?
    var expectedNextEvent: String = "None"
    var lastReceivedEvent: String = "None"
    var expectedDelegate: String = "None"
    var pendingAckMessage: String?
    var pendingAckSentTime: Date?
    var proxyFilterUpdatedCount = 0
    private var watchdogTimer: Timer?
    private var watchdogTicks = 0
    private let maxWatchdogTicks = 3

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
        guard !isConfiguring else {
            return ConfigurationServiceResponse(isSuccess: false, message: "Already configuring")
        }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              appDelegate.meshState == .proxyConnected else {
            return ConfigurationServiceResponse(isSuccess: false, message: "Invalid state for configureNode")
        }

        // Trace ID と Watchdog の初期化
        configTraceId = UUID()
        let traceIdStr = configTraceId?.uuidString ?? "N/A"
        expectedNextEvent = "ConfigAppKeyStatus"
        expectedDelegate = "ConfigAppKeyStatus"
        lastReceivedEvent = "configureNode Called"
        
        MeshTrace.log(
            traceId: traceIdStr,
            step: "CONFIGURING",
            event: "START",
            node: "\(unicastAddress)",
            state: "PROXY_CONNECTED",
            detail: "configureNode started. Initializing trace and watchdog."
        )

        isConfiguring = true
        appDelegate.meshState = .configuring
        startWatchdog(for: unicastAddress)

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
                let detailErr = "No ApplicationKey available"
                MeshTrace.log(
                    traceId: traceIdStr,
                    step: "APP_KEY_ADD",
                    event: "ERROR",
                    node: "\(unicastAddress)",
                    state: "CONFIGURING",
                    detail: detailErr
                )
                stopWatchdog()
                isConfiguring = false
                appDelegate.meshState = .proxyConnected // 元に戻す
                return ConfigurationServiceResponse(
                    isSuccess: false,
                    message: detailErr
                )
            }

            // AppKeyの追加
            let appKeyCount = manager.meshNetwork?.applicationKeys.count ?? 0
            let isConnected = appDelegate.connection?.isConnected ?? false
            let detailBefore = "Sending ConfigAppKeyAdd. AppKey Index: \(selectedAppKey.index). AppKeys count: \(appKeyCount). Connected: \(isConnected). Node UUID: \(node.uuid.uuidString). Node Addr: \(node.primaryUnicastAddress)"
            
            MeshTrace.log(
                traceId: traceIdStr,
                step: "APP_KEY_ADD",
                event: "SEND_PRE",
                node: "\(unicastAddress)",
                state: "CONFIGURING",
                detail: detailBefore
            )
            
            trackAckSent(messageType: "ConfigAppKeyAdd")
            try manager.send(
                ConfigAppKeyAdd(applicationKey: selectedAppKey),
                to: node
            )

            let detailAfter = "Sent ConfigAppKeyAdd successfully. Awaiting AppKey status response..."
            MeshTrace.log(
                traceId: traceIdStr,
                step: "APP_KEY_ADD",
                event: "SEND_POST_SUCCESS",
                node: "\(unicastAddress)",
                state: "CONFIGURING",
                detail: detailAfter
            )

            return ConfigurationServiceResponse(
                isSuccess: true,
                message: "Configuration process started. Awaiting AppKey status response..."
            )

        } catch {
            let detailErr = "Failed to configure the node: \(error.localizedDescription)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "APP_KEY_ADD",
                event: "SEND_POST_FAILURE",
                node: "\(unicastAddress)",
                state: "CONFIGURING",
                detail: detailErr
            )
            stopWatchdog()
            isConfiguring = false
            appDelegate.meshState = .proxyConnected
            return ConfigurationServiceResponse(
                isSuccess: false,
                message: detailErr
            )
        }
    }

    func setSubscription(withAddress address: Address)
        -> ConfigurationServiceResponse
    {
        guard !isSubscribed else {
            return ConfigurationServiceResponse(isSuccess: false, message: "Already subscribed")
        }
        let traceIdStr = configTraceId?.uuidString ?? "N/A"
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let stateStr = appDelegate?.meshState.rawValue ?? "UNKNOWN"
        
        MeshTrace.log(
            traceId: traceIdStr,
            step: "SUBSCRIPTION",
            event: "START",
            node: "\(address)",
            state: stateStr,
            detail: "setSubscription started"
        )
        
        expectedNextEvent = "ConfigModelSubscriptionStatus"
        expectedDelegate = "ConfigModelSubscriptionStatus"

        var node: Node!
        var serverModel: Model!
        var clientModelID: UInt16?
        var targetGroup: Group?

        // ノードを探す
        do {
            node = try findNode(withUnicastAddress: address)
        } catch {
            let detailErr = "setSubscription failed: Couldn't find node with address \(address)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "SUBSCRIPTION",
                event: "NODE_NOT_FOUND_ERROR",
                node: "\(address)",
                state: stateStr,
                detail: detailErr
            )
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
            let detailErr = "setSubscription failed: Couldn't find server model for address \(address)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "SUBSCRIPTION",
                event: "SERVER_MODEL_NOT_FOUND",
                node: "\(address)",
                state: stateStr,
                detail: detailErr
            )
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
            let detailErr = "setSubscription failed: Failed to find client model \(clientModelID)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "SUBSCRIPTION",
                event: "CLIENT_MODEL_NOT_FOUND",
                node: "\(address)",
                state: stateStr,
                detail: detailErr
            )
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
                let detailErr = "setSubscription failed: Failed to add group: \(error.localizedDescription)"
                MeshTrace.log(
                    traceId: traceIdStr,
                    step: "SUBSCRIPTION",
                    event: "GROUP_ADD_ERROR",
                    node: "\(address)",
                    state: stateStr,
                    detail: detailErr
                )
                return ConfigurationServiceResponse(
                    isSuccess: false,
                    message:
                        "Failed to add group: \(error.localizedDescription)"
                )
            }
        }

        guard let targetGroup else {
            let detailErr = "setSubscription failed: Failed to find group"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "SUBSCRIPTION",
                event: "GROUP_NOT_FOUND",
                node: "\(address)",
                state: stateStr,
                detail: detailErr
            )
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
            
        let isConnected = appDelegate?.connection?.isConnected ?? false
        let detailSendPre = "Sending ConfigModelSubscriptionAdd to ServerModel (ID: \(serverModel.modelIdentifier)). Group Address: \(targetGroup.address). Connected: \(isConnected)"
        MeshTrace.log(
            traceId: traceIdStr,
            step: "SUBSCRIPTION",
            event: "SEND_PRE",
            node: "\(address)",
            state: stateStr,
            detail: detailSendPre
        )
        
        do {
            trackAckSent(messageType: "ConfigModelSubscriptionAdd")
            try MeshNetworkManager.instance.send(message, to: node)
            
            let detailSendPost = "Sent ConfigModelSubscriptionAdd successfully."
            MeshTrace.log(
                traceId: traceIdStr,
                step: "SUBSCRIPTION",
                event: "SEND_POST_SUCCESS",
                node: "\(address)",
                state: stateStr,
                detail: detailSendPost
            )
        } catch {
            let detailSendFail = "Failed to send ConfigModelSubscriptionAdd: \(error.localizedDescription)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "SUBSCRIPTION",
                event: "SEND_POST_FAILURE",
                node: "\(address)",
                state: stateStr,
                detail: detailSendFail
            )
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
        guard !isPublished else {
            return ConfigurationServiceResponse(isSuccess: false, message: "Already published")
        }
        let traceIdStr = configTraceId?.uuidString ?? "N/A"
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let stateStr = appDelegate?.meshState.rawValue ?? "UNKNOWN"
        
        MeshTrace.log(
            traceId: traceIdStr,
            step: "PUBLICATION",
            event: "START",
            node: "\(address)",
            state: stateStr,
            detail: "setPublication started"
        )
        
        expectedNextEvent = "ConfigModelPublicationStatus"
        expectedDelegate = "ConfigModelPublicationStatus"

        isPublished = true

        var node: Node!
        var serverModel: Model!
        var clientModelID: UInt16?

        // ノードを探す
        do {
            node = try findNode(withUnicastAddress: address)
        } catch {
            let detailErr = "setPublication failed: Couldn't find node with address \(address)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "PUBLICATION",
                event: "NODE_NOT_FOUND_ERROR",
                node: "\(address)",
                state: stateStr,
                detail: detailErr
            )
            isPublished = false
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
            let detailErr = "setPublication failed: Couldn't find server model for address \(address)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "PUBLICATION",
                event: "SERVER_MODEL_NOT_FOUND",
                node: "\(address)",
                state: stateStr,
                detail: detailErr
            )
            isPublished = false
            return ConfigurationServiceResponse(
                isSuccess: false,
                message: "Couldn't find server model"
            )
        }

        guard let clientModelID,
            let clientModel = manager.localElements.flatMap({ $0.models })
                .first(where: { $0.modelIdentifier == clientModelID })
        else {
            let detailErr = "setPublication failed: Failed to find client model \(clientModelID)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "PUBLICATION",
                event: "CLIENT_MODEL_NOT_FOUND",
                node: "\(address)",
                state: stateStr,
                detail: detailErr
            )
            isPublished = false
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
            let detailErr = "setPublication failed: Group not found for publication"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "PUBLICATION",
                event: "GROUP_NOT_FOUND",
                node: "\(address)",
                state: stateStr,
                detail: detailErr
            )
            isPublished = false
            return ConfigurationServiceResponse(
                isSuccess: false,
                message: "Group not found"
            )
        }

        guard let applicationKey = clientModel.boundApplicationKeys.first else {
            let detailErr = "setPublication failed: Bound ApplicationKey not found for client model \(clientModelID)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "PUBLICATION",
                event: "APP_KEY_NOT_BOUND",
                node: "\(address)",
                state: stateStr,
                detail: detailErr
            )
            isPublished = false
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
            
        let isConnected = appDelegate?.connection?.isConnected ?? false
        let detailSendPre = "Sending ConfigModelPublicationSet to ServerModel. Group Address: \(targetGroup.address). ApplicationKey: \(applicationKey.index). Connected: \(isConnected)"
        MeshTrace.log(
            traceId: traceIdStr,
            step: "PUBLICATION",
            event: "SEND_PRE",
            node: "\(address)",
            state: stateStr,
            detail: detailSendPre
        )
        
        do {
            trackAckSent(messageType: "ConfigModelPublicationSet")
            try MeshNetworkManager.instance.send(
                publicationMessage,
                to: node,
                withTtl: UInt8(3)
            )
            
            let detailSendPost = "Sent ConfigModelPublicationSet successfully."
            MeshTrace.log(
                traceId: traceIdStr,
                step: "PUBLICATION",
                event: "SEND_POST_SUCCESS",
                node: "\(address)",
                state: stateStr,
                detail: detailSendPost
            )
        } catch {
            let detailSendFail = "Failed to send ConfigModelPublicationSet: \(error.localizedDescription)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "PUBLICATION",
                event: "SEND_POST_FAILURE",
                node: "\(address)",
                state: stateStr,
                detail: detailSendFail
            )
            isPublished = false
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
        logNodeResolution(forAddress: unicastAddress, step: "NODE_RESOLUTION", event: "FIND_NODE_CALL")
        guard let node = manager.meshNetwork?.node(withAddress: unicastAddress)
        else {
            let traceIdStr = configTraceId?.uuidString ?? "N/A"
            let stateStr = (UIApplication.shared.delegate as? AppDelegate)?.meshState.rawValue ?? "UNKNOWN"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "NODE_RESOLUTION",
                event: "FIND_NODE_FAILED",
                node: "\(unicastAddress)",
                state: stateStr,
                detail: "Could not find node in meshNetwork.nodes!"
            )
            throw ConfigurationServiceError.nodeNotFound
        }
        return node
    }
}

// MARK: - ACK, Watchdog and Resolution Helpers

extension ConfigurationService {
    
    /// 新しいプロビジョニング/コンフィグレーションセッション開始前に全ステートをリセット
    func resetForNewSession() {
        isConfiguring = false
        isSubscribed = false
        isPublished = false
        currentTargetAddress = nil
        configTraceId = nil
        expectedNextEvent = "None"
        lastReceivedEvent = "None"
        expectedDelegate = "None"
        pendingAckMessage = nil
        pendingAckSentTime = nil
        proxyFilterUpdatedCount = 0
        stopWatchdog()
    }
    
    func trackAckSent(messageType: String) {
        self.pendingAckMessage = messageType
        self.pendingAckSentTime = Date()
    }

    func logNodeResolution(forAddress address: Address, uuidString: String? = nil, step: String, event: String) {
        let traceIdStr = configTraceId?.uuidString ?? "N/A"
        let stateStr = (UIApplication.shared.delegate as? AppDelegate)?.meshState.rawValue ?? "UNKNOWN"
        let network = manager.meshNetwork
        let allNodes = network?.nodes ?? []
        let nodesSummary = allNodes.map { "Node(addr: \($0.primaryUnicastAddress), uuid: \($0.uuid.uuidString), name: \($0.name ?? "N/A"))" }.joined(separator: ", ")
        
        var uuidMatchStr = "None"
        if let uuidStr = uuidString, let uuid = UUID(uuidString: uuidStr) {
            if let match = allNodes.first(where: { $0.uuid == uuid }) {
                uuidMatchStr = "Node(addr: \(match.primaryUnicastAddress), uuid: \(match.uuid.uuidString))"
            }
        }
        
        var addressMatchStr = "None"
        if let match = network?.node(withAddress: address) {
            addressMatchStr = "Node(addr: \(match.primaryUnicastAddress), uuid: \(match.uuid.uuidString))"
        }
        
        let detail = "Nodes count: \(allNodes.count). Nodes: [\(nodesSummary)]. UUID Match for \(uuidString ?? "nil"): \(uuidMatchStr). Address Match for \(address): \(addressMatchStr)"
        
        MeshTrace.log(
            traceId: traceIdStr,
            step: step,
            event: event,
            node: "\(address)",
            state: stateStr,
            detail: detail
        )
    }

    func startWatchdog(for nodeAddress: Address) {
        watchdogTimer?.invalidate()
        watchdogTicks = 0
        watchdogTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.watchdogTicks += 1
            let traceIdStr = self.configTraceId?.uuidString ?? "N/A"
            let node = self.manager.meshNetwork?.node(withAddress: nodeAddress)
            
            var nodeDump = "Node not found for address \(nodeAddress)"
            if let node = node {
                let boundKeys = node.elements.flatMap { $0.models }.flatMap { $0.boundApplicationKeys }.map { "\($0.index)" }.joined(separator: ",")
                nodeDump = "Node(addr: \(nodeAddress), uuid: \(node.uuid.uuidString), boundAppKeys: [\(boundKeys)])"
            }
            
            let proxyConnected = (UIApplication.shared.delegate as? AppDelegate)?.connection?.isConnected ?? false
            let hasTransmitter = self.manager.transmitter != nil
            
            // proxyFilterの状態
            let filterType = self.manager.proxyFilter.type
            let filterAddresses = self.manager.proxyFilter.addresses
            let filterState = "FilterType: \(filterType), Addresses: \(filterAddresses)"
            
            let detail = "Watchdog tick. Expected: \(self.expectedNextEvent), ExpectedDelegate: \(self.expectedDelegate), LastReceived: \(self.lastReceivedEvent), PendingAck: \(self.pendingAckMessage ?? "None"), Dump: \(nodeDump), ProxyConnected: \(proxyConnected), HasTransmitter: \(hasTransmitter), ProxyFilter: \(filterState)"
            
            MeshTrace.log(
                traceId: traceIdStr,
                step: "WATCHDOG",
                event: "TICK",
                node: "\(nodeAddress)",
                state: (UIApplication.shared.delegate as? AppDelegate)?.meshState.rawValue ?? "UNKNOWN",
                detail: detail
            )
            
            // 15秒応答なしでのアクティブリカバリ
            if self.watchdogTicks >= self.maxWatchdogTicks {
                MeshTrace.log(traceId: traceIdStr, step: "WATCHDOG", event: "TIMEOUT", node: "\(nodeAddress)", state: (UIApplication.shared.delegate as? AppDelegate)?.meshState.rawValue ?? "UNKNOWN", detail: "No response for 15s. Aborting sequence.")
                
                self.stopWatchdog()
                self.isConfiguring = false
                self.isSubscribed = false
                self.isPublished = false
                
                var eventType = "configuration"
                if self.expectedNextEvent == "ConfigModelSubscriptionStatus" { eventType = "subscription" }
                else if self.expectedNextEvent == "ConfigModelPublicationStatus" { eventType = "publication" }
                
                MeshNetworkEventStreamHandler.shared.sendEvent(status: .error, data: ["message": "タイムアウト: デバイスからの応答がありません", "eventType": eventType])
            }
        }
    }

    func stopWatchdog() {
        watchdogTimer?.invalidate()
        watchdogTimer = nil
    }
    
    /// コンフィグレーション完了時に呼ぶ（isConfiguringリセット含む）
    func markConfigurationComplete() {
        isConfiguring = false
        currentTargetAddress = nil
        stopWatchdog()
    }
}

import os.log

class MeshTrace {
    static let logSubsystem = "com.soccerapp.mesh"
    static let logCategory = "Trace"
    static let osLog = OSLog(subsystem: logSubsystem, category: logCategory)

    static func log(
        traceId: String,
        step: String,
        event: String,
        node: String,
        state: String,
        detail: String
    ) {
        let message = "[\(traceId)] [\(step)] [\(event)] [\(node)] [\(state)] [\(detail)]"
        print(message)
    }
}
