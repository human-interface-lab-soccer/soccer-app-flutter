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
        // ProvisioningService は自身で GeneralBleScanner と連携するようにします。
        // または、AppDelegate で BleScanner を初期化し、ProvisioningService に渡すことも可能です。
        // ここでは、ProvisioningService が BleScanner を内部で管理する想定で記述します。
        self.bleScanner = GeneralBleScanner()  // BleScanner はここで保持し、ProvisioningServiceに渡す
        self.provisioningService = ProvisioningService(
            meshNetworkManager: meshNetworkManager,
            bleScanner: self.bleScanner!  // ProvisioningService に BleScanner を渡す
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

// MARK: - MeshNetworkManager Extension & Dummy Delegate

// このExtensionは AppDelegate が MeshNetworkManager.instance を提供するために残しますが、
// 将来的にはDI (Dependency Injection) コンテナや他の設計パターンを用いて、
// グローバルなシングルトンアクセスを避けることを検討するべきです。
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
