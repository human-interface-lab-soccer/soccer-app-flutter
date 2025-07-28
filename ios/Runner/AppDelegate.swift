import CoreBluetooth
import Flutter
import NordicMesh
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    // MARK: - Properties

    static let attentionTimer: UInt8 = 5

    // BLE Scanner
    private var generalBleScanner: GeneralBleScanner?

    // Mesh Network
    var meshNetworkManager: MeshNetworkManager!
    var connection: NetworkConnection?

    // Provisioning
    private var bearer: ProvisioningBearer?
    private var unprovisionedDevice: UnprovisionedDevice?
    private var provisioningManager: ProvisioningManager?

    // Flutter Communication
    private var scannerEventChannel: FlutterEventChannel!
    private var provisioningEventChannel: FlutterEventChannel!
    private var provisioningEventSink: FlutterEventSink?

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

        // Flutter Channels
        setupMethodChannels(with: controller.binaryMessenger)
        setupEventChannels(with: controller.binaryMessenger)

        // Initialize Mesh Network
        initializeMeshNetwork()

        GeneratedPluginRegistrant.register(with: self)
        return super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }

    // MARK: - Channel Setup

    private func setupMethodChannels(with messenger: FlutterBinaryMessenger) {
        let scannerMethodChannel = FlutterMethodChannel(
            name: "human.mech.saitama-u.ac.jp/scannerMethodChannel",
            binaryMessenger: messenger
        )
        let provisioningMethodChannel = FlutterMethodChannel(
            name: "human.mech.saitama-u.ac.jp/provisioningMethodChannel",
            binaryMessenger: messenger
        )

        scannerMethodChannel.setMethodCallHandler {
            [weak self] (call, result) in
            self?.handleScannerMethod(call: call, result: result)
        }

        provisioningMethodChannel.setMethodCallHandler {
            [weak self] (call, result) in
            self?.handleProvisioningMethod(call: call, result: result)
        }
    }

    private func setupEventChannels(with messenger: FlutterBinaryMessenger) {
        scannerEventChannel = FlutterEventChannel(
            name: "human.mech.saitama-u.ac.jp/scannerEventChannel",
            binaryMessenger: messenger
        )

        provisioningEventChannel = FlutterEventChannel(
            name: "human.mech.saitama-u.ac.jp/provisioningEventChannel",
            binaryMessenger: messenger
        )
        provisioningEventChannel.setStreamHandler(self)
    }

    // MARK: - Method Handlers

    private func handleScannerMethod(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch call.method {
        case "startScanning":
            if generalBleScanner == nil {
                generalBleScanner = GeneralBleScanner()
                scannerEventChannel.setStreamHandler(generalBleScanner)
            }
            generalBleScanner?.startScan()
            result("Started Scan...")
        case "stopScanning":
            generalBleScanner?.stopScan()
            generalBleScanner = nil
            scannerEventChannel.setStreamHandler(nil)
            result("Stopped Scan.")
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleProvisioningMethod(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch call.method {
        case "provisioning":
            guard let args = call.arguments as? [String: String],
                let uuidString = args["uuid"]
            else {
                result([
                    "isSuccess": false,
                    "body": "UUID key not found in arguments.",
                ])
                return
            }
            let provisioningResult = startProvisioningProcess(for: uuidString)
            result(provisioningResult)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Mesh Network Setup

    private func initializeMeshNetwork() {
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

    // MARK: - Provisioning Logic

    private func startProvisioningProcess(for uuid: String) -> [String: Any] {
        // ★★★ 修正点：まず古いセッション情報をクリアする ★★★
        cleanupProvisioning(closeBearer: true)

        guard let deviceInfo = generalBleScanner?.discoveredDevicesList[uuid],
            let peripheral = deviceInfo["peripheral"] as? CBPeripheral,
            let advertisementData = deviceInfo["advertisementData"]
                as? [String: Any]
        else {
            return [
                "isSuccess": false, "body": "Device not found in scan results.",
            ]
        }

        guard
            let unprovisionedDevice = UnprovisionedDevice(
                advertisementData: advertisementData
            )
        else {
            return [
                "isSuccess": false,
                "body": "The device is not a valid unprovisioned device.",
            ]
        }

        // ★★★ 修正点：クリア処理を移動したため、このプロパティは保持される ★★★
        self.unprovisionedDevice = unprovisionedDevice

        let bearer = PBGattBearer(target: peripheral)
        bearer.delegate = self
        bearer.dataDelegate = meshNetworkManager
        self.bearer = bearer

        do {
            try? bearer.open()
            sendProvisioningEvent(
                status: "connecting",
                data: [
                    "message":
                        "Connecting to \(unprovisionedDevice.name ?? "device")..."
                ]
            )
            return [
                "isSuccess": true, "body": "Provisioning process initiated.",
            ]
        } catch {
            cleanupProvisioning()
            return [
                "isSuccess": false,
                "body": "Failed to open bearer: \(error.localizedDescription)",
            ]
        }
    }

    private func startProvisioning() {
        guard let provisioningManager = self.provisioningManager,
            let capabilities = provisioningManager.provisioningCapabilities
        else {
            sendProvisioningEvent(
                status: "error",
                data: [
                    "message":
                        "Cannot start provisioning: capabilities not available."
                ]
            )
            return
        }

        sendProvisioningEvent(
            status: "provisioning",
            data: ["message": "Provisioning..."]
        )

        if provisioningManager.networkKey == nil {
            guard let network = meshNetworkManager.meshNetwork else { return }

            if let primaryKey = network.networkKeys.first {
                provisioningManager.networkKey = primaryKey
            } else {
                do {
                    let newKey = try network.add(
                        networkKey: Data.random128BitKey(),
                        name: "Primary Network Key"
                    )
                    provisioningManager.networkKey = newKey
                } catch {
                    sendProvisioningEvent(
                        status: "error",
                        data: [
                            "message":
                                "Failed to create network key: \(error.localizedDescription)"
                        ]
                    )
                    return
                }
            }
        }

        do {
            try provisioningManager.provision(
                usingAlgorithm: capabilities.algorithms.strongest,
                publicKey: .noOobPublicKey,
                authenticationMethod: .noOob
            )
        } catch {
            sendProvisioningEvent(
                status: "error",
                data: [
                    "message":
                        "Failed to start provisioning: \(error.localizedDescription)"
                ]
            )
            try? bearer?.close()
        }
    }

    private func sendProvisioningEvent(status: String, data: [String: Any]) {
        print("[provisioningEvent] status: \(status), data: \(data)")

        guard let sink = provisioningEventSink else { return }
        DispatchQueue.main.async {
            var eventData = data
            eventData["status"] = status
            sink(eventData)
        }
    }

    private func cleanupProvisioning(closeBearer: Bool = false) {
        if closeBearer {
            try? self.bearer?.close()
        }
        self.bearer = nil
        self.unprovisionedDevice = nil
        self.provisioningManager = nil
    }
}

// MARK: - FlutterStreamHandler

extension AppDelegate: FlutterStreamHandler {
    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        self.provisioningEventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.provisioningEventSink = nil
        return nil
    }
}

// MARK: - GattBearerDelegate

extension AppDelegate: GattBearerDelegate {
    func bearerDidConnect(_ bearer: Bearer) {
        sendProvisioningEvent(
            status: "connecting",
            data: ["message": "Discovering services..."]
        )
    }

    func bearerDidDiscoverServices(_ bearer: Bearer) {
        sendProvisioningEvent(
            status: "connecting",
            data: ["message": "Initializing..."]
        )
    }

    func bearerDidOpen(_ bearer: Bearer) {
        guard let unprovisionedDevice = self.unprovisionedDevice,
            let provisioningBearer = bearer as? ProvisioningBearer
        else {
            sendProvisioningEvent(
                status: "error",
                data: ["message": "Internal error: Device or bearer invalid."]
            )
            return
        }

        sendProvisioningEvent(
            status: "identifying",
            data: ["message": "Identifying device..."]
        )

        do {
            provisioningManager = try meshNetworkManager.provision(
                unprovisionedDevice: unprovisionedDevice,
                over: provisioningBearer
            )
            provisioningManager!.delegate = self
            try provisioningManager!.identify(
                andAttractFor: AppDelegate.attentionTimer
            )
        } catch {
            // ★★★ 修正点：その他のエラー ★★★
            sendProvisioningEvent(
                status: "error",
                data: [
                    "message":
                        "Provisioning setup failed: \(error.localizedDescription)"
                ]
            )
            try? self.bearer?.close()
        }
    }

    func bearer(_ bearer: Bearer, didClose error: Error?) {
        guard let state = provisioningManager?.state else {
            sendProvisioningEvent(
                status: "disconnected",
                data: ["message": "Device disconnected."]
            )
            cleanupProvisioning()
            print("Fail to connect")
            return
        }

        if case .complete = state {
            if meshNetworkManager.save() {
                guard
                    let node = meshNetworkManager.meshNetwork?.node(
                        for: self.unprovisionedDevice!
                    )
                else {
                    sendProvisioningEvent(
                        status: "error",
                        data: ["message": "Provisioned node not found."]
                    )
                    cleanupProvisioning()
                    return
                }
                sendProvisioningEvent(
                    status: "complete",
                    data: [
                        "message": "Provisioning complete!",
                        "nodeUuid": node.uuid.uuidString,
                        "unicastAddress": node.primaryUnicastAddress,
                    ]
                )
            } else {
                sendProvisioningEvent(
                    status: "error",
                    data: [
                        "message": "Failed to save mesh network configuration."
                    ]
                )
            }
        } else {
            sendProvisioningEvent(
                status: "error",
                data: [
                    "message":
                        "Disconnected: \(error?.localizedDescription ?? "Unknown reason")"
                ]
            )
        }
        cleanupProvisioning()
    }
}

// MARK: - ProvisioningDelegate

extension AppDelegate: ProvisioningDelegate {
    func provisioningState(
        of unprovisionedDevice: UnprovisionedDevice,
        didChangeTo state: ProvisioningState
    ) {
        DispatchQueue.main.async {
            switch state {
            case .requestingCapabilities:
                self.sendProvisioningEvent(
                    status: "identifying",
                    data: ["message": "Requesting capabilities..."]
                )

            case let .capabilitiesReceived(capabilities):
                let capsData: [String: Any] = [
                    "numberOfElements": capabilities.numberOfElements,
                    "algorithms": "\(capabilities.algorithms)",
                    "publicKeyType": "\(capabilities.publicKeyType)",
                    "oobType": "\(capabilities.oobType)",
                ]
                self.sendProvisioningEvent(
                    status: "capabilitiesReceived",
                    data: capsData
                )
                // Automatically start provisioning after receiving capabilities
                self.startProvisioning()

            case .complete:
                self.sendProvisioningEvent(
                    status: "provisioning",
                    data: ["message": "Finalizing..."]
                )
            // The final "complete" state is handled in `bearerDidClose`

            case let .failed(error):
                self.sendProvisioningEvent(
                    status: "error",
                    data: [
                        "message":
                            "Provisioning failed: \(error.localizedDescription)"
                    ]
                )
                try? self.bearer?.close()

            default:
                break
            }
        }
    }

    func authenticationActionRequired(_ action: AuthAction) {
        // This implementation only supports NoOOB.
        sendProvisioningEvent(
            status: "error",
            data: ["message": "Authentication required but not supported."]
        )
        try? bearer?.close()
    }

    func inputComplete() {
        sendProvisioningEvent(
            status: "provisioning",
            data: ["message": "Input complete. Provisioning..."]
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
