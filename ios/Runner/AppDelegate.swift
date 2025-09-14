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
            provisioningService: provisioningService,
//            meshNetowrkEventStreamHandler: meshNetworkEventStreamHandler!
        )
        flutterChannelManager.setupChannels()
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
