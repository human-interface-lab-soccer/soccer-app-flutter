import Flutter
import NordicMesh
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    // MARK: - Properties

    // Manager Instances
    var meshNetworkManager: MeshNetworkManager!
    var connection: NetworkConnection?
    private var bleScanner: GeneralBleScanner?
    private var provisioningService: ProvisioningService!
    private var flutterChannelManager: FlutterChannelManager!

    // Retry variables for ConfigCompositionDataGet
    private var compositionDataTimer: Timer?
    private var compositionDataRetries = 0
    private let maxCompositionDataRetries = 3

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
        meshNetworkManager.networkParameters = .default

        do {
            if try meshNetworkManager.load() {
                meshNetworkDidChange()
            } else {
                _ = createNewMeshNetwork()
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
                )
            ]
        )
        meshNetworkManager.localElements = [primaryElement]

        connection = NetworkConnection(to: meshNetwork)
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
            provisioningService: provisioningService
        )
        flutterChannelManager.setupChannels()
    }
}

// MARK: - MeshNetworkDelegate
extension AppDelegate: MeshNetworkDelegate {
    // MARK: GATT Proxy接続成功時の処理
    func meshNetworkManager(
        _ manager: MeshNetworkManager,
        didConnectToProxy: Node
    ) {
        print(
            "Connected to GATT Proxy: \(didConnectToProxy.name ?? "Unknown Proxy")"
        )

        // 接続成功後、ConfigurationServiceを呼び出す前に遅延を入れる
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // ConfigurationServiceのシングルトンインスタンスを直接使用する
            _ = ConfigurationService.shared.configureNode(
                unicastAddress: didConnectToProxy.primaryUnicastAddress
            )
        }
    }

    func meshNetworkManager(
        _ manager: NordicMesh.MeshNetworkManager,
        didReceiveMessage message: any NordicMesh.MeshMessage,
        sentFrom source: NordicMesh.Address,
        to destination: NordicMesh.MeshAddress
    ) {
        print("================================")

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
        // AppKeyが正常に追加されたことをFlutterに通知
        if appKeyStatus.status == .success {
            print("AppKey added successfully.")
            // AppKeyの追加成功後、Composition Dataをリクエストする（リトライあり）
            sendCompositionDataRequest(to: node)

        } else {
            print(
                "Failed to add AppKey: \(appKeyStatus.status.debugDescription)"
            )
            return
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
            withTimeInterval: 5.0,
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
        // AppKeyとGeneric OnOff Serverモデルを見つける
        guard
            let appKey = manager.meshNetwork?.applicationKeys.first(where: {
                node.knows(networkKey: $0.boundNetworkKey)
            }),
            let genericOnOffServerModel = node.elements
                .flatMap({ $0.models })
                .first(where: { $0.name == "Generic OnOff Server" })
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
        } else {
            print("Model bind failed with status: \(modelAppStatus.status)")
        }
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
