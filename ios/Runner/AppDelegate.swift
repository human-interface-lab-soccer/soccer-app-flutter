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

        if message is ConfigCompositionDataStatus {
            print("Received Composition Data from \(source)")
            //            if let node = manager.meshNetwork?.node(withAddress: source) {
            //                // まず AppKey を追加
            //                if let appKey = manager.meshNetwork?.applicationKeys.first {
            //                    try manager.send(
            //                        ConfigAppKeyAdd(applicationKey: appKey),
            //                        to: node
            //                    )
            //                }
            //            }

            // TODO: リファクタリング
            // 分岐が多すぎるから，do-catch とか guard使って綺麗にしたい(?)
        } else if let appKeyStatus = message as? ConfigAppKeyStatus {
            print("Received AppKeyStatus: \(appKeyStatus.status)")
            if appKeyStatus.status == .success {
                // AppKey の追加が成功したのでモデルにバインド
                if let node = manager.meshNetwork?.node(withAddress: source),
                    let availableKeys = manager.meshNetwork?.applicationKeys
                {
                    var appKey: ApplicationKey?
                    let keys = availableKeys.filter {
                        node.knows(networkKey: $0.boundNetworkKey)
                    }
                    if !keys.isEmpty {
                        appKey = keys[0]
                    }
                    guard let selectedAppKey = appKey else {
                        print("Failed to select AppKey")
                        return
                    }

                    for element in node.elements {
                        if let model = element.models.first(where: {
                            $0.name == "Generic OnOff Server"
                        }) {
                            if let bindMessage = ConfigModelAppBind(
                                applicationKey: selectedAppKey,
                                to: model
                            ) {
                                print("Model: \(model.name)")
                                do {
                                    try manager.send(
                                        bindMessage,
                                        to: node
                                    )
                                    print(
                                        "Sent ConfigModelAppBind to \(model.name ?? "Unknown Model")"
                                    )
                                } catch {
                                    print(
                                        "Failed to bind AppKey to model: \(error.localizedDescription)"
                                    )
                                }

                            }
                        }
                    }
                }
            }

        } else if let modelStatus = message as? ConfigModelAppStatus {
            print("ModelAppBind status: \(modelStatus.status)")
            if modelStatus.status == .success {
                print("AppKey successfully bound to model!")
            }
        }
        // else の処理が実装されていない
        // else {}
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
