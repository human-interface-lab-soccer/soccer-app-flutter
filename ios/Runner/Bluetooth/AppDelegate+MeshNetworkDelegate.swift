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
        // ノード解決ログ（受信メッセージのソースアドレスを解決する際）
        ConfigurationService.shared.logNodeResolution(
            forAddress: source,
            step: "NODE_RESOLUTION",
            event: "MESSAGE_RECEIVED"
        )

        let traceIdStr = ConfigurationService.shared.configTraceId?.uuidString ?? "N/A"
        let receivedType = "\(type(of: message))"
        let expectedAck = ConfigurationService.shared.pendingAckMessage
        
        var match = false
        var durationMs: Double = -1.0
        
        if let pendingAck = expectedAck {
            let isAppKeyMatch = (pendingAck == "ConfigAppKeyAdd" && receivedType == "ConfigAppKeyStatus")
            let isCompositionMatch = (pendingAck == "ConfigCompositionDataGet" && receivedType == "ConfigCompositionDataStatus")
            let isModelBindMatch = (pendingAck == "ConfigModelAppBind" && receivedType == "ConfigModelAppStatus")
            let isSubMatch = (pendingAck == "ConfigModelSubscriptionAdd" && receivedType == "ConfigModelSubscriptionStatus")
            let isPubMatch = (pendingAck == "ConfigModelPublicationSet" && receivedType == "ConfigModelPublicationStatus")
            
            if isAppKeyMatch || isCompositionMatch || isModelBindMatch || isSubMatch || isPubMatch {
                match = true
            }
            
            if let sentTime = ConfigurationService.shared.pendingAckSentTime {
                durationMs = Date().timeIntervalSince(sentTime) * 1000.0
            }
        }
        
        let ackDetail = "Received \(receivedType) from \(source). PendingAck: \(expectedAck ?? "None"). Match: \(match). Duration: \(durationMs >= 0 ? String(format: "%.1fms", durationMs) : "N/A")"
        MeshTrace.log(
            traceId: traceIdStr,
            step: "ACK_TRACKING",
            event: "RECEIVED",
            node: "\(source)",
            state: meshState.rawValue,
            detail: ackDetail
        )
        
        if match {
            ConfigurationService.shared.pendingAckMessage = nil
            ConfigurationService.shared.pendingAckSentTime = nil
        }

        // nodeを探す
        guard let node = manager.meshNetwork?.node(withAddress: source) else {
            MeshTrace.log(
                traceId: traceIdStr,
                step: "DELEGATE_RECEIVE",
                event: "NODE_NOT_FOUND_ERROR",
                node: "\(source)",
                state: meshState.rawValue,
                detail: "Couldn't find node with address \(source) in meshNetwork.nodes"
            )
            return
        }

        switch message {
        case is ConfigCompositionDataStatus:
            guard meshState == .waitComposition else { return }
            
            let statusDetail = "Received Composition Data Status from \(source). Invaliding timer."
            MeshTrace.log(
                traceId: traceIdStr,
                step: "COMPOSITION_DATA",
                event: "STATUS_RECEIVED",
                node: "\(source)",
                state: meshState.rawValue,
                detail: statusDetail
            )
            
            compositionDataTimer?.invalidate()
            compositionDataTimer = nil
            
            ConfigurationService.shared.lastReceivedEvent = "ConfigCompositionDataStatus Received"
            ConfigurationService.shared.expectedNextEvent = "ConfigModelAppStatus"
            ConfigurationService.shared.expectedDelegate = "ConfigModelAppStatus"
            
            handleCompositionDataStatus(
                node: node,
                manager: manager
            )

        case let appKeyStatus as ConfigAppKeyStatus:
            guard meshState == .configuring else { return }
            
            let statusDetail = "Received AppKeyStatus: \(appKeyStatus.status) from \(source)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "APP_KEY_ADD",
                event: "STATUS_RECEIVED",
                node: "\(source)",
                state: meshState.rawValue,
                detail: statusDetail
            )
            
            ConfigurationService.shared.lastReceivedEvent = "ConfigAppKeyStatus Received"
            ConfigurationService.shared.expectedNextEvent = "ConfigCompositionDataStatus"
            ConfigurationService.shared.expectedDelegate = "ConfigCompositionDataStatus"
            
            handleAppKeyStatus(
                appKeyStatus: appKeyStatus,
                manager: manager,
                node: node
            )

        case let modelStatus as ConfigModelAppStatus:
            guard meshState == .configuring else { return }
            
            let statusDetail = "Received ConfigModelAppStatus: \(modelStatus.status) from \(source)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "MODEL_APP_BIND",
                event: "STATUS_RECEIVED",
                node: "\(source)",
                state: meshState.rawValue,
                detail: statusDetail
            )
            
            // ローカル（アドレス1）へのバインドに対する応答は無視し、リモートノードからの応答のみを処理する
            if source == Address(0x0001) {
                let localDetail = "Received local Client Model AppBind status. Skipping state transition."
                MeshTrace.log(
                    traceId: traceIdStr,
                    step: "MODEL_APP_BIND",
                    event: "LOCAL_STATUS_IGNORED",
                    node: "\(source)",
                    state: meshState.rawValue,
                    detail: localDetail
                )
                return
            }
            
            ConfigurationService.shared.lastReceivedEvent = "ConfigModelAppStatus Received"
            ConfigurationService.shared.expectedNextEvent = "ConfigModelSubscriptionStatus"
            ConfigurationService.shared.expectedDelegate = "ConfigModelSubscriptionStatus"
            
            Task {
                await handleModelAppStatus(
                    modelAppStatus: modelStatus,
                    manager: manager,
                    node: node
                )
            }

        case let configSubscriptionState as ConfigModelSubscriptionStatus:
            guard meshState == .subscription, !ConfigurationService.shared.isSubscribed else { return }
            ConfigurationService.shared.isSubscribed = true
            
            ConfigurationService.shared.lastReceivedEvent = "ConfigModelSubscriptionStatus Received"
            ConfigurationService.shared.expectedNextEvent = "ConfigModelPublicationStatus"
            ConfigurationService.shared.expectedDelegate = "ConfigModelPublicationStatus"
            
            if configSubscriptionState.isSuccess {
                _ = manager.save()
                let statusDetail = "Successfully subscribe model for \(source)"
                MeshTrace.log(
                    traceId: traceIdStr,
                    step: "SUBSCRIPTION",
                    event: "SUCCESS",
                    node: "\(source)",
                    state: meshState.rawValue,
                    detail: statusDetail
                )
                
                sendFlutterEvent(
                    status: .success,
                    message: "Successfully subscribe model",
                    eventType: "subscription"
                )
                
                if !ConfigurationService.shared.isPublished {
                    meshState = .publication
                    let result = ConfigurationService.shared.setPublication(withAddress: source)
                    
                    let triggerDetail = "Publication triggered: \(result.isSuccess) - \(result.message)"
                    MeshTrace.log(
                        traceId: traceIdStr,
                        step: "PUBLICATION",
                        event: "TRIGGER",
                        node: "\(source)",
                        state: meshState.rawValue,
                        detail: triggerDetail
                    )
                }
            } else {
                ConfigurationService.shared.isSubscribed = false
                ConfigurationService.shared.isConfiguring = false
                ConfigurationService.shared.stopWatchdog()
                
                let statusDetail = "Failed to subscribe model: \(configSubscriptionState.message) for \(source)"
                MeshTrace.log(
                    traceId: traceIdStr,
                    step: "SUBSCRIPTION",
                    event: "FAILURE",
                    node: "\(source)",
                    state: meshState.rawValue,
                    detail: statusDetail
                )
                
                sendFlutterEvent(
                    status: .error,
                    message: "Failed to subscribe model: \(configSubscriptionState.message)",
                    eventType: "subscription"
                )
            }

        case let configPublicationStatus as ConfigModelPublicationStatus:
            guard meshState == .publication else { return }
            
            ConfigurationService.shared.lastReceivedEvent = "ConfigModelPublicationStatus Received"
            ConfigurationService.shared.expectedNextEvent = "Flow Complete"
            ConfigurationService.shared.expectedDelegate = "None"
            
            if configPublicationStatus.status == .success {
                ConfigurationService.shared.markConfigurationComplete() // 正常終了: isConfiguring リセット + Watchdog停止
                _ = manager.save()
                let statusDetail = "Successfully publish model for \(source)"
                MeshTrace.log(
                    traceId: traceIdStr,
                    step: "PUBLICATION",
                    event: "SUCCESS",
                    node: "\(source)",
                    state: meshState.rawValue,
                    detail: statusDetail
                )
                
                sendFlutterEvent(
                    status: .success,
                    message: "Successfully publish model",
                    eventType: "publication"
                )
            } else {
                ConfigurationService.shared.isPublished = false
                ConfigurationService.shared.isConfiguring = false
                ConfigurationService.shared.stopWatchdog()
                
                let statusDetail = "Failed to publish model: \(configPublicationStatus.message) for \(source)"
                MeshTrace.log(
                    traceId: traceIdStr,
                    step: "PUBLICATION",
                    event: "FAILURE",
                    node: "\(source)",
                    state: meshState.rawValue,
                    detail: statusDetail
                )
                
                sendFlutterEvent(
                    status: .error,
                    message: "Failed to publish model: \(configPublicationStatus.message)",
                    eventType: "publication"
                )
            }

        case is ConfigNodeResetStatus:
            let statusDetail = "Received ConfigNodeResetStatus from \(source). Removing node from database."
            MeshTrace.log(
                traceId: traceIdStr,
                step: "RESET_NODE",
                event: "SUCCESS",
                node: "\(source)",
                state: meshState.rawValue,
                detail: statusDetail
            )
            
            if let meshNetwork = manager.meshNetwork {
                meshNetwork.remove(node: node)
                _ = manager.save()
            }
            sendFlutterEvent(
                status: .success,
                message: "Node successfully reset and removed from database",
                eventType: "resetNode"
            )

        default:
            let detailUnknown = "Received unknown message type: \(receivedType)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "DELEGATE_RECEIVE",
                event: "UNKNOWN_MESSAGE",
                node: "\(source)",
                state: meshState.rawValue,
                detail: detailUnknown
            )
        }
    }

    private func handleAppKeyStatus(
        appKeyStatus: ConfigAppKeyStatus,
        manager: MeshNetworkManager,
        node: Node
    ) {
        let traceIdStr = ConfigurationService.shared.configTraceId?.uuidString ?? "N/A"
        if appKeyStatus.status == .success {
            _ = manager.save()
            let detail = "AppKey added successfully. Transitioning to waitComposition."
            MeshTrace.log(
                traceId: traceIdStr,
                step: "APP_KEY_ADD",
                event: "STATUS_SUCCESS",
                node: "\(node.primaryUnicastAddress)",
                state: meshState.rawValue,
                detail: detail
            )
            meshState = .waitComposition
            
            ConfigurationService.shared.startWatchdog(for: node.primaryUnicastAddress)
            ConfigurationService.shared.expectedNextEvent = "ConfigCompositionDataStatus"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.sendCompositionDataRequest(to: node)
            }
        } else {
            let detail = "Failed to add AppKey: \(appKeyStatus.status.debugDescription)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "APP_KEY_ADD",
                event: "STATUS_FAILURE",
                node: "\(node.primaryUnicastAddress)",
                state: meshState.rawValue,
                detail: detail
            )
            ConfigurationService.shared.stopWatchdog()
            sendFlutterEvent(
                status: .error,
                message: "Failed to add AppKey: \(appKeyStatus.status.debugDescription)",
                eventType: "configuration"
            )
        }
    }

    // ConfigCompositionDataGet を送信するリトライロジック
    func sendCompositionDataRequest(to node: Node) {
        guard compositionDataTimer == nil else { return }
        compositionDataRetries = 0

        sendCompositionDataMessage(to: node)

        compositionDataTimer = Timer.scheduledTimer(
            withTimeInterval: retryTimeInterval,
            repeats: true
        ) { [weak self] _ in
            guard let self = self else { return }

            self.compositionDataRetries += 1
            let isConnected = self.connection?.isConnected ?? false
            let nodeDump = "Node(addr: \(node.primaryUnicastAddress), uuid: \(node.uuid.uuidString))"
            let detail = "Composition Data Get TIMEOUT. Retry count: \(self.compositionDataRetries)/\(self.maxCompositionDataRetries). NodeDump: \(nodeDump). Connected: \(isConnected)"
            
            MeshTrace.log(
                traceId: ConfigurationService.shared.configTraceId?.uuidString ?? "N/A",
                step: "COMPOSITION_DATA",
                event: "TIMEOUT",
                node: "\(node.primaryUnicastAddress)",
                state: self.meshState.rawValue,
                detail: detail
            )

            if self.compositionDataRetries <= self.maxCompositionDataRetries {
                self.sendCompositionDataMessage(to: node)
            } else {
                self.compositionDataTimer?.invalidate()
                self.compositionDataTimer = nil
                ConfigurationService.shared.stopWatchdog() // タイムアウト諦めたらWatchdogも切る
            }
        }
    }

    private func sendCompositionDataMessage(to node: Node) {
        let isConnected = connection?.isConnected ?? false
        let transmitterState = meshNetworkManager.transmitter != nil ? "Available" : "Nil"
        let nodeDump = "Node(addr: \(node.primaryUnicastAddress), uuid: \(node.uuid.uuidString))"
        let filterType = meshNetworkManager.proxyFilter.type
        let filterAddresses = meshNetworkManager.proxyFilter.addresses
        let filterState = "FilterType: \(filterType), Addresses: \(filterAddresses)"
        
        let detail = "Sending ConfigCompositionDataGet. NodeDump: \(nodeDump). ProxyFilter: \(filterState). Transmitter: \(transmitterState). Connected: \(isConnected)"
        
        MeshTrace.log(
            traceId: ConfigurationService.shared.configTraceId?.uuidString ?? "N/A",
            step: "COMPOSITION_DATA",
            event: "SEND_PRE",
            node: "\(node.primaryUnicastAddress)",
            state: meshState.rawValue,
            detail: detail
        )

        do {
            ConfigurationService.shared.currentMessageHandle?.cancel()
            ConfigurationService.shared.trackAckSent(messageType: "ConfigCompositionDataGet")
            ConfigurationService.shared.currentMessageHandle = try meshNetworkManager.send(ConfigCompositionDataGet(), to: node)
            
            let detailSuccess = "Sent ConfigCompositionDataGet successfully to \(node.name ?? "Unknown Node")"
            MeshTrace.log(
                traceId: ConfigurationService.shared.configTraceId?.uuidString ?? "N/A",
                step: "COMPOSITION_DATA",
                event: "SEND_POST_SUCCESS",
                node: "\(node.primaryUnicastAddress)",
                state: meshState.rawValue,
                detail: detailSuccess
            )
        } catch {
            let detailFail = "Failed to send ConfigCompositionDataGet: \(error.localizedDescription)"
            MeshTrace.log(
                traceId: ConfigurationService.shared.configTraceId?.uuidString ?? "N/A",
                step: "COMPOSITION_DATA",
                event: "SEND_POST_FAILURE",
                node: "\(node.primaryUnicastAddress)",
                state: meshState.rawValue,
                detail: detailFail
            )
        }
    }

    private func handleCompositionDataStatus(
        node: Node,
        manager: MeshNetworkManager
    ) {
        let traceIdStr = ConfigurationService.shared.configTraceId?.uuidString ?? "N/A"
        guard meshState == .waitComposition else {
            let detail = "handleCompositionDataStatus: invalid state \(meshState.rawValue)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "COMPOSITION_DATA",
                event: "STATE_ERROR",
                node: "\(node.primaryUnicastAddress)",
                state: meshState.rawValue,
                detail: detail
            )
            return
        }
        
        guard let appKey = manager.meshNetwork?.applicationKeys.first(where: {
            node.knows(networkKey: $0.boundNetworkKey)
        }) else {
            let detail = "handleCompositionDataStatus: AppKey not found on node"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "COMPOSITION_DATA",
                event: "APPKEY_ERROR",
                node: "\(node.primaryUnicastAddress)",
                state: meshState.rawValue,
                detail: detail
            )
            ConfigurationService.shared.stopWatchdog()
            return
        }
        
        guard let connection = self.connection, connection.isConnected else {
            let detail = "handleCompositionDataStatus: GATT proxy not connected"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "COMPOSITION_DATA",
                event: "PROXY_ERROR",
                node: "\(node.primaryUnicastAddress)",
                state: meshState.rawValue,
                detail: detail
            )
            ConfigurationService.shared.stopWatchdog()
            return
        }
        
        meshState = .configuring

        let clientUnicastAddress = Address(0x0001)
        var serverModel: Model?
        var clientModelID: UInt16?

        let models = node.elements.flatMap({ $0.models })

        if let genericOnOffServerModel = models.first(where: {
            UInt16($0.modelId) == .genericOnOffServerModelId
        }) {
            serverModel = genericOnOffServerModel
            clientModelID = .genericOnOffClientModelId
        }
        else if let genericColorServerModel = models.first(where: {
            UInt16($0.modelId) == .genericColorServerModelID
        }) {
            serverModel = genericColorServerModel
            clientModelID = .genericColorClientModelID
        }
        else {
            let detail = "Valid server model not found"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "COMPOSITION_DATA",
                event: "MODEL_ERROR",
                node: "\(node.primaryUnicastAddress)",
                state: meshState.rawValue,
                detail: detail
            )
            ConfigurationService.shared.stopWatchdog()
            sendFlutterEvent(
                status: .error,
                message: "Valid server model not found",
                eventType: "configuration"
            )
            return
        }

        bindModel(
            model: serverModel!,
            appKey: appKey,
            manager: manager,
            node: node
        )

        guard
            let clientModel = manager.localElements
                .flatMap({ $0.models })
                .first(where: {
                    $0.modelIdentifier == clientModelID
                })
        else {
            let detail = "Failed to find client model"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "MODEL_APP_BIND",
                event: "CLIENT_MODEL_ERROR",
                node: "\(clientUnicastAddress)",
                state: meshState.rawValue,
                detail: detail
            )
            ConfigurationService.shared.stopWatchdog()
            return
        }
        do {
            guard
                let clientBindMessage = ConfigModelAppBind(
                    applicationKey: appKey,
                    to: clientModel
                )
            else {
                let detail = "Failed to create client-model-bind message"
                MeshTrace.log(
                    traceId: traceIdStr,
                    step: "MODEL_APP_BIND",
                    event: "CLIENT_MESSAGE_ERROR",
                    node: "\(clientUnicastAddress)",
                    state: meshState.rawValue,
                    detail: detail
                )
                ConfigurationService.shared.stopWatchdog()
                return
            }
            
            let detailSendPre = "Sending local Client Model Bind (ID: \(clientModel.modelIdentifier)) to ClientUnicastAddress: \(clientUnicastAddress)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "MODEL_APP_BIND",
                event: "SEND_PRE_CLIENT",
                node: "\(clientUnicastAddress)",
                state: meshState.rawValue,
                detail: detailSendPre
            )
            
            ConfigurationService.shared.trackAckSent(messageType: "ConfigModelAppBind")
            ConfigurationService.shared.currentMessageHandle = try manager.send(clientBindMessage, to: clientUnicastAddress)

            let detailSendPost = "Sent local Client Model Bind successfully."
            MeshTrace.log(
                traceId: traceIdStr,
                step: "MODEL_APP_BIND",
                event: "SEND_POST_CLIENT_SUCCESS",
                node: "\(clientUnicastAddress)",
                state: meshState.rawValue,
                detail: detailSendPost
            )
        } catch {
            let detailSendFail = "Failed to send local Client Model Bind: \(error.localizedDescription)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "MODEL_APP_BIND",
                event: "SEND_POST_CLIENT_FAILURE",
                node: "\(clientUnicastAddress)",
                state: meshState.rawValue,
                detail: detailSendFail
            )
            ConfigurationService.shared.stopWatchdog()
            return
        }
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
        
        let traceIdStr = ConfigurationService.shared.configTraceId?.uuidString ?? "N/A"
        let detailSendPre = "Sending ConfigModelAppBind to ServerModel (ID: \(model.modelIdentifier)) for address \(node.primaryUnicastAddress)"
        MeshTrace.log(
            traceId: traceIdStr,
            step: "MODEL_APP_BIND",
            event: "SEND_PRE_SERVER",
            node: "\(node.primaryUnicastAddress)",
            state: meshState.rawValue,
            detail: detailSendPre
        )
        
        do {
            ConfigurationService.shared.trackAckSent(messageType: "ConfigModelAppBind")
            ConfigurationService.shared.currentMessageHandle = try manager.send(bindMessage, to: node)
            
            let detailSendPost = "Sent ConfigModelAppBind successfully."
            MeshTrace.log(
                traceId: traceIdStr,
                step: "MODEL_APP_BIND",
                event: "SEND_POST_SERVER_SUCCESS",
                node: "\(node.primaryUnicastAddress)",
                state: meshState.rawValue,
                detail: detailSendPost
            )
        } catch {
            let detailSendFail = "Failed to send ConfigModelAppBind: \(error.localizedDescription)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "MODEL_APP_BIND",
                event: "SEND_POST_SERVER_FAILURE",
                node: "\(node.primaryUnicastAddress)",
                state: meshState.rawValue,
                detail: detailSendFail
            )
        }
    }

    private func handleModelAppStatus(
        modelAppStatus: ConfigModelAppStatus,
        manager: MeshNetworkManager,
        node: Node
    ) async {
        let traceIdStr = ConfigurationService.shared.configTraceId?.uuidString ?? "N/A"
        if modelAppStatus.status == .success {
            _ = manager.save()
            let detail = "Successfully bind AppKey to Model. Transitioning to subscription."
            MeshTrace.log(
                traceId: traceIdStr,
                step: "MODEL_APP_BIND",
                event: "STATUS_SUCCESS",
                node: "\(node.primaryUnicastAddress)",
                state: meshState.rawValue,
                detail: detail
            )
            
            sendFlutterEvent(
                status: .success,
                message: "Successfully bind AppKey to Model",
                eventType: "configuration"
            )
            
            if !ConfigurationService.shared.isSubscribed {
                meshState = .subscription
                let result = ConfigurationService.shared.setSubscription(withAddress: node.primaryUnicastAddress)
                
                let triggerDetail = "Subscription triggered: \(result.isSuccess) - \(result.message)"
                MeshTrace.log(
                    traceId: traceIdStr,
                    step: "SUBSCRIPTION",
                    event: "TRIGGER",
                    node: "\(node.primaryUnicastAddress)",
                    state: meshState.rawValue,
                    detail: triggerDetail
                )
            }
        } else {
            let detail = "Model bind failed with status: \(modelAppStatus.status)"
            MeshTrace.log(
                traceId: traceIdStr,
                step: "MODEL_APP_BIND",
                event: "STATUS_FAILURE",
                node: "\(node.primaryUnicastAddress)",
                state: meshState.rawValue,
                detail: detail
            )
            ConfigurationService.shared.stopWatchdog()
            sendFlutterEvent(
                status: .error,
                message: "Model bind failed with status: \(modelAppStatus.status)",
                eventType: "configuration"
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
                message: "Failed to find models",
                eventType: "colorSet"
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
            sendFlutterEvent(
                status: .success,
                message: "Successfully sent message",
                eventType: "colorSet"
            )
        } catch {
            sendFlutterEvent(
                status: .error,
                message:
                    "Failed to send message: \(error.localizedDescription)",
                eventType: "colorSet"
            )
        }
    }

    private func sendFlutterEvent(status: MeshNetworkStatus, message: String?, eventType: String? = nil) {
        var data: [String: Any] = ["message": message ?? "No message"]
        if let eventType = eventType {
            data["eventType"] = eventType
        }
        MeshNetworkEventStreamHandler.shared.sendEvent(
            status: status,
            data: data
        )
    }
}
