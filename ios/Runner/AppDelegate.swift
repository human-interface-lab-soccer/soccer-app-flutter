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

extension AppDelegate: MeshNetworkDelegate {
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
            // TODO: applicationKeyの追加の処理をこっちに移行する
            print("Received Composition Data from \(source)")

        // AppKey追加後のモデルバインド処理を行う
        case let appKeyStatus as ConfigAppKeyStatus:
            print("Received AppKeyStatus: \(appKeyStatus.status)")
            handleAppKeyStatus(
                appKeyStatus: appKeyStatus,
                manager: manager,
                node: node
            )

        // モデルバインドの成否を確認する
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
        var appKey: ApplicationKey?
        do {
            appKey = try findApplicationKey(manager: manager, node: node)
        } catch {
            print("Failed to find applicationKey")
            return
        }

        guard
            let genericOnOffServerModel = node.elements
                .flatMap({ $0.models })
                .first(where: { $0.name == "Generic OnOff Server" })
        else {
            print("Model not found")
            return
        }

        bindModel(
            model: genericOnOffServerModel,
            appKey: appKey!,  // TODO: guard let でappKeyの強制アンラップを外す処理を追加
            manager: manager,
            node: node
        )
    }

    private func findApplicationKey(manager: MeshNetworkManager, node: Node)
        throws -> ApplicationKey
    {
        guard let availableKeys = manager.meshNetwork?.applicationKeys,
            !availableKeys.isEmpty
        else {
            print("No available applicationKeys")
            throw FindApplicationKeyError.noAvailableApplicationKeys
        }
        guard
            let selectedAppKey = availableKeys.first(where: {
                node.knows(networkKey: $0.boundNetworkKey)
            })
        else {
            throw FindApplicationKeyError.noSuitableApplicationKeyFound
        }
        return selectedAppKey
    }

    /// ApplicationKey を探す際のエラー
    private enum FindApplicationKeyError: Error, LocalizedError {
        case noAvailableApplicationKeys
        case noSuitableApplicationKeyFound

        var errorDescription: String? {
            switch self {
            case .noAvailableApplicationKeys:
                return "No available ApplicationKeys"
            case .noSuitableApplicationKeyFound:
                return "No suitable ApplicationKey found"
            }
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
        do {
            try manager.send(bindMessage, to: node)
            print("Sent ConfigModelAppBind to \(model.name ?? "Unknown Model")")
        } catch {
            print(
                "Failed to bind AppKey to model: \(error.localizedDescription)"
            )
        }
    }

    // TODO: 中身を実装する
    private func handleModelAppStatus(
        modelAppStatus: ConfigModelAppStatus,
        manager: MeshNetworkManager,
        node: Node
    ) {

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
