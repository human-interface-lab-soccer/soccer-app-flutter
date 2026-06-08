import Flutter
import NordicMesh
import UIKit

enum MeshState: String {
    case provisioning = "PROVISIONING"
    case provisioningComplete = "PROVISIONING_COMPLETE"
    case waitProxyConnection = "WAIT_PROXY_CONNECTION"
    case proxyConnected = "PROXY_CONNECTED"
    case waitComposition = "WAIT_COMPOSITION"
    case configuring = "CONFIGURING"
    case complete = "COMPLETE"
    case subscription = "SUBSCRIPTION"
    case publication = "PUBLICATION"
}

@main
@objc class AppDelegate: FlutterAppDelegate {

    // MARK: - Properties
 
    private let stateQueue = DispatchQueue(label: "com.soccerapp.mesh.state")
    private var _meshState: MeshState = .complete
    
    var meshState: MeshState {
        get {
            return stateQueue.sync { _meshState }
        }
        set {
            stateQueue.async { [weak self] in
                guard let self = self else { return }
                let oldValue = self._meshState
                guard oldValue != newValue else {
                    return
                }
                
                DispatchQueue.main.async {
                    self._meshState = newValue
                    let previousState = oldValue.rawValue
                    let nextState = newValue.rawValue
                    let isMain = Thread.isMainThread ? "main" : "background"
                    let stackTrace = Thread.callStackSymbols.prefix(5).joined(separator: " | ")
                    let nodeRef = ConfigurationService.shared.currentTargetAddress != nil ? "\(ConfigurationService.shared.currentTargetAddress!)" : "nil"
                    let traceIdStr = ConfigurationService.shared.configTraceId?.uuidString ?? "N/A"
                    
                    MeshTrace.log(
                        traceId: traceIdStr,
                        step: "STATE_TRANSITION",
                        event: "CHANGE",
                        node: nodeRef,
                        state: nextState,
                        detail: "Transition: \(previousState) -> \(nextState) | Thread: \(isMain) | Stack: \(stackTrace)"
                    )
                    
                    self.sendFlutterMeshStateEvent(state: newValue)
                }
            }
        }
    }

    // Manager Instances
    var meshNetworkManager: MeshNetworkManager!
    var connection: NetworkConnection?
    private let defaultTtl: UInt8 = 127 // Bluetooth Mesh 仕様上の Default TTL の最大値 0x7F (127) に設定して安定化を図る
    private var bleScanner: GeneralBleScanner?
    private var provisioningService: ProvisioningService!
    private var flutterChannelManager: FlutterChannelManager!

    // Retry variables for ConfigCompositionDataGet
    var compositionDataTimer: Timer?
    var compositionDataRetries = 0
    let maxCompositionDataRetries = 3
    let retryTimeInterval = 5.0

    // MARK: - Application Lifecycle

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]?
    ) -> Bool {
        guard
            let controller = window?.rootViewController
                as? FlutterViewController
        else {
            fatalError("rootViewController is not type FlutterViewController")
        }

        // Initialize Managers
        initializeMeshNetworkManager()
        initializeProvisioningService()
        setupFlutterChannels(with: controller.binaryMessenger)
        meshNetworkManager.delegate = self

        GeneratedPluginRegistrant.register(with: self)
        return super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }

    // MARK: - Initialization

    private func initializeMeshNetworkManager() {
        meshNetworkManager = MeshNetworkManager()
        meshNetworkManager.proxyFilter.delegate = self
        meshNetworkManager.networkParameters = .default

        do {
            if try meshNetworkManager.load() {
                meshNetworkDidChange()
            } else {
                _ = createNewMeshNetwork()
            }

            if let provisioner = meshNetworkManager.meshNetwork?
                .localProvisioner, provisioner.node?.defaultTTL == nil
            {
                provisioner.node?.defaultTTL = defaultTtl
                let _ = meshNetworkManager.save()
            }
        } catch {
            print("Error loading mesh network: \(error)")
            _ = createNewMeshNetwork()
        }
    }

    private func createNewMeshNetwork() -> MeshNetwork {
        let provisioner = Provisioner(
            name: UIDevice.current.name,
            allocatedUnicastRange: [AddressRange(0x0001...0x199A)],
            allocatedGroupRange: [AddressRange(0xC000...0xCC9A)],
            allocatedSceneRange: [SceneRange(0x0001...0x3333)]
        )
        let network = meshNetworkManager.createNewMeshNetwork(
            withName: "My Flutter Mesh",
            by: provisioner
        )
        if let localProvisioner = network.localProvisioner {
            localProvisioner.node?.defaultTTL = defaultTtl
        }
        _ = meshNetworkManager.save()
        meshNetworkDidChange()
        return network
    }

    private func meshNetworkDidChange() {
        connection?.close()

        guard let meshNetwork = meshNetworkManager.meshNetwork else { return }

        let primaryElement = Element(
            name: "Primary Element",
            location: .first,
            models: [
                Model(
                    sigModelId: .genericOnOffClientModelId,
                    delegate: GenericOnOffClientDelegate()
                ),
                Model(
                    sigModelId: .genericColorClientModelID,
                    delegate: GenericColorClientDelegate()
                ),
            ]
        )
        meshNetworkManager.localElements = [primaryElement]

        connection = NetworkConnection(to: meshNetwork)
        connection!.delegate = self
        connection!.dataDelegate = meshNetworkManager
        meshNetworkManager.transmitter = connection

        do {
            try connection!.open()
        } catch {
            print("Failed to open network connection: \(error)")
        }
    }

    private func initializeProvisioningService() {
        self.bleScanner = GeneralBleScanner()
        self.provisioningService = ProvisioningService(
            meshNetworkManager: meshNetworkManager,
            bleScanner: self.bleScanner!
        )
    }

    private func setupFlutterChannels(with messenger: FlutterBinaryMessenger) {
        flutterChannelManager = FlutterChannelManager(
            messenger: messenger,
            bleScanner: bleScanner!,
            provisioningService: provisioningService,
        )
        flutterChannelManager.setupChannels()
    }

    private func sendFlutterMeshStateEvent(state: MeshState) {
        MeshNetworkEventStreamHandler.shared.sendEvent(
            status: .processing,
            data: [
                "eventType": "meshStateChanged",
                "meshState": state.rawValue,
                "message": "State transitioned to \(state.rawValue)"
            ]
        )
    }
}

// MARK: - MeshNetworkManager Extension & Dummy Delegate

extension MeshNetworkManager {
    static var instance: MeshNetworkManager {
        if Thread.isMainThread {
            return (UIApplication.shared.delegate as! AppDelegate)
                .meshNetworkManager
        } else {
            return DispatchQueue.main.sync {
                return (UIApplication.shared.delegate as! AppDelegate)
                    .meshNetworkManager
            }
        }
    }

    static var bearer: NetworkConnection! {
        if Thread.isMainThread {
            return (UIApplication.shared.delegate as! AppDelegate).connection
        } else {
            return DispatchQueue.main.sync {
                return (UIApplication.shared.delegate as! AppDelegate)
                    .connection
            }
        }
    }
}

extension AppDelegate: ProxyFilterDelegate {
    func proxyFilterUpdated(type: ProxyFilerType, addresses: Set<Address>) {
        ConfigurationService.shared.proxyFilterUpdatedCount += 1
        let count = ConfigurationService.shared.proxyFilterUpdatedCount
        let targetAddress = ConfigurationService.shared.currentTargetAddress
        let targetMatch = targetAddress != nil ? addresses.contains(targetAddress!) : false
        let traceIdStr = ConfigurationService.shared.configTraceId?.uuidString ?? "N/A"
        
        let detail = "Proxy filter updated count: \(count). Type: \(type), Addresses: \(addresses). TargetAddress: \(targetAddress != nil ? String(targetAddress!) : "nil"). Match: \(targetMatch)"
        
        MeshTrace.log(
            traceId: traceIdStr,
            step: "PROXY_FILTER",
            event: "UPDATED",
            node: targetAddress != nil ? "\(targetAddress!)" : "nil",
            state: meshState.rawValue,
            detail: detail
        )
        
        if meshState == .proxyConnected {
            guard let targetAddress = ConfigurationService.shared.currentTargetAddress else {
                let errDetail = "[ProxyFilterDelegate] Error: currentTargetAddress is nil"
                MeshTrace.log(
                    traceId: traceIdStr,
                    step: "PROXY_FILTER",
                    event: "ERROR",
                    node: "nil",
                    state: meshState.rawValue,
                    detail: errDetail
                )
                return
            }
            if !ConfigurationService.shared.isConfiguring {
                // ターゲットがまだフィルターに入っていない場合
                if !addresses.contains(targetAddress) {
                    // SDKのデフォルト設定（1 や 65535 の追加）が終わっているか確認する
                    let localAddress = meshNetworkManager.meshNetwork?.localProvisioner?.unicastAddress ?? 1
                    
                    if addresses.contains(localAddress) || addresses.contains(.allProxies) {
                        // デフォルト設定が完了していれば、ここで安全にターゲットを追加！
                        let waitDetail = "[ProxyFilterDelegate] Default filter setup complete. Now adding target \(targetAddress)"
                        MeshTrace.log(
                            traceId: traceIdStr,
                            step: "PROXY_FILTER",
                            event: "ADDING_TARGET",
                            node: "\(targetAddress)",
                            state: meshState.rawValue,
                            detail: waitDetail
                        )
                        meshNetworkManager.proxyFilter.add(address: targetAddress)
                    } else {
                        // まだ空っぽ（初期化中）の場合は待つ
                        let waitDetail = "[ProxyFilterDelegate] Filter initializing... waiting."
                        MeshTrace.log(
                            traceId: traceIdStr,
                            step: "PROXY_FILTER",
                            event: "WAITING_FOR_INITIALIZATION",
                            node: "\(targetAddress)",
                            state: meshState.rawValue,
                            detail: waitDetail
                        )
                    }
                    return
                }
                
                let infoDetail = "[ProxyFilterDelegate] Found target address \(targetAddress) in filter, triggering configureNode"
                MeshTrace.log(
                    traceId: traceIdStr,
                    step: "PROXY_FILTER",
                    event: "TRIGGER_CONFIGURE_NODE",
                    node: "\(targetAddress)",
                    state: meshState.rawValue,
                    detail: infoDetail
                )
                let result = ConfigurationService.shared.configureNode(unicastAddress: targetAddress)
                
                let resultDetail = "[ProxyFilterDelegate] configureNode triggered: \(result.isSuccess) - \(result.message)"
                MeshTrace.log(
                    traceId: traceIdStr,
                    step: "PROXY_FILTER",
                    event: "CONFIGURE_NODE_RESULT",
                    node: "\(targetAddress)",
                    state: meshState.rawValue,
                    detail: resultDetail
                )
            }
        }
    }
}

extension AppDelegate: BearerDelegate {
    func bearerDidOpen(_ bearer: Bearer) {
        print("[ProxyDelegate] bearerDidOpen callback. Current state: \(meshState.rawValue)")
        if meshState == .waitProxyConnection {
            meshState = .proxyConnected
        }
    }

    func bearer(_ bearer: Bearer, didClose error: Error?) {
        print("[ProxyDelegate] bearerDidClose callback. Current state: \(meshState.rawValue)")
        
        // SDK内部のproxyNetworkKeyをnilにリセットし、次の接続で
        // newProxyDidConnect()が確実に呼ばれるようにする
        meshNetworkManager.proxyFilter.proxyDidDisconnect()
        
        // プロビジョニング中などの意図的な切断時に、勝手にProxy接続を再開しないようにする
        if meshState == .waitComposition || meshState == .configuring || meshState == .proxyConnected || meshState == .waitProxyConnection {
            meshState = .waitProxyConnection
            if let connection = connection {
                do {
                    try connection.open()
                } catch {
                    print("Failed to reopen connection: \(error.localizedDescription)")
                }
            }
        }
    }
}


