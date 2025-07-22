import Flutter
import NordicMesh
import UIKit
import CoreBluetooth

@main
@objc class AppDelegate: FlutterAppDelegate, BearerDelegate {

    private var generalBleScanner: GeneralBleScanner?
    
    var meshNetworkManager: MeshNetworkManager!
    var connection: NetworkConnection!
    var provisioningManager: ProvisioningManager!

    var pendingProvisioning: (ProvisioningManager, PublicKey, AuthenticationMethod)? = nil
    var pendingDevice: UnprovisionedDevice?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let scannerEventChannel = FlutterEventChannel(
            name: "human.mech.saitama-u.ac.jp/scannerEventChannel",
            binaryMessenger: controller.binaryMessenger
        )
        let scannerMethodChannel = FlutterMethodChannel(
            name: "human.mech.saitama-u.ac.jp/scannerMethodChannel",
            binaryMessenger: controller.binaryMessenger
        )
        let provisioningMethodChannel = FlutterMethodChannel(
            name: "human.mech.saitama-u.ac.jp/provisioningMethodChannel",
            binaryMessenger: controller.binaryMessenger
        )
        
        initializeMeshNetwork()
        
        scannerMethodChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else {
                return;
            }

            switch call.method {
            case "startScanning":
                if self.generalBleScanner == nil {
                    self.generalBleScanner = GeneralBleScanner()
                    scannerEventChannel.setStreamHandler(self.generalBleScanner)
                }
                self.generalBleScanner?.startScan()
                result("[ScannerMethodChannel] Started Scan...")
            case "stopScanning":
                self.generalBleScanner?.stopScan()
                self.generalBleScanner = nil
                result("[ScannerMethodChannel] Stop Scan...")
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        
        provisioningMethodChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else {
                return;
            }
            
            switch call.method {
            case "provisioning":
                let args = call.arguments as? [String: String]
                if let uuidString = args?["uuid"] {
                    let provisioningStatus = self.provisioning(uuid: uuidString)
                    result(provisioningStatus)
                } else {
                    result(["isSuccess": false, "Body": "uuidキーが見つかりません"])
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func createNewMeshNetwork() -> MeshNetwork {
        let provisioner = Provisioner(
            name: UIDevice.current.name,
            allocatedUnicastRange: [AddressRange(0x0001...0x199A)],
            allocatedGroupRange:   [AddressRange(0xC000...0xCC9A)],
            allocatedSceneRange:   [SceneRange(0x0001...0x3333)]
        )
        let network = meshNetworkManager.createNewMeshNetwork(withName: "nRF Mesh Network", by: provisioner)
        _ = meshNetworkManager.save()
        
        meshNetworkDidChange()
        
        return network
    }
    
    func meshNetworkDidChange() {
        print("MESH NETWORK DID CHANGED")
        connection?.close()
        
        let meshNetwork = meshNetworkManager.meshNetwork!
        
        // Set up Local Node
        // refer to https://nordicsemiconductor.github.io/IOS-nRF-Mesh-Library/documentation/nordicmesh/localnode
        let primaryElement = Element(
            name: "Primary Element",
            location: .first,
            models: [
                Model(sigModelId: .genericLevelClientModelId, delegate: GenericOnOffClientDelegate()),
            ]
        )
        meshNetworkManager.localElements = [primaryElement]

        connection = NetworkConnection(to: meshNetwork)
        connection.dataDelegate = meshNetworkManager
        meshNetworkManager.transmitter = connection
        connection!.open()
    }

    func initializeMeshNetwork() -> Void {
        meshNetworkManager = MeshNetworkManager()
//        meshNetworkManager.networkParameters = .default
        meshNetworkManager.networkParameters = .basic { parameters in
            parameters.setDefaultTtl(5)
            parameters.discardIncompleteSegmentedMessages(after: 10.0)
            parameters.transmitSegmentAcknowledgmentMessage(
                usingSegmentReceptionInterval: 0.06,
                multipliedByMinimumDelayIncrement: 2.5
            )
            parameters.retransmitSegmentAcknowledgmentMessages(
                exactly: 1, timesWhenNumberOfSegmentsIsGreaterThan: 3)
            parameters.transmitSegments(withInterval: 0.06)
            parameters.retransmitUnacknowledgedSegmentsToUnicastAddress(
                atMost: 2, timesAndWithoutProgress: 2,
                timesWithRetransmissionInterval: 0.200, andIncrement: 2.5)
            parameters.retransmitAllSegmentsToGroupAddress(exactly: 3, timesWithInterval: 0.250)
            parameters.retransmitAcknowledgedMessage(after: 4.2)
            parameters.discardAcknowledgedMessages(after: 40.0)
        }

        // Creating and loading a network configuration
        do {
            if try meshNetworkManager.load() {
                meshNetworkDidChange()
            } else {
                let network = createNewMeshNetwork()
                print("Mesh Network", network)
            }
        } catch {
            print("ERROR!!!!", error)
        }
    }

    func provisioning(uuid: String) -> [String: Any?] {
        // UUIDからスキャン済みデバイスを検索
        guard let deviceInfo = generalBleScanner?.discoveredDevicesList[uuid] else {
            // デバイスが見つからない場合はError
            return ["Status": "Failed to connect target device", "Body": ""]
        }
        let peripheral = deviceInfo["peripheral"] as! CBPeripheral
        let advertisementData = deviceInfo["advertisementData"] as! [String: Any]
        print("-----")
        print(advertisementData)
        print("-----")
//        let manager = MeshNetworkManager.instance
        
        let bearer: ProvisioningBearer = PBGattBearer(target: peripheral)
        bearer.delegate = self
        bearer.dataDelegate = meshNetworkManager
        meshNetworkManager.transmitter = bearer as ProvisioningBearer
//        peripheral.delegate = bearer
        try? bearer.open()
        
        print("opening bearer ...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            print("Bearer isOpen: ", bearer.isOpen)
        }

        // unprovisioning deviceにしてみる
        if let unprovisionedDevice = UnprovisionedDevice(advertisementData: advertisementData) {
//            let bearer: ProvisioningBearer = PBGattBearer(target: peripheral)
//            bearer.delegate = self
//            bearer.dataDelegate = meshNetworkManager
//            meshNetworkManager.transmitter = bearer
//            peripheral.delegate = bearer
//            bearer.open()
//            print("opening bearer ...")
//            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
//                print("Bearer isOpen: ", bearer.isOpen)
//            }
            
            pendingDevice = unprovisionedDevice
            
            return ["isSuccess": true, "Body": nil]
//            do {
//                let provisioningManager = try manager.provision(
//                    unprovisionedDevice: unprovisionedDevice,
//                    over: bearer
//                )
////                self.provisioningManager = provisioningManager
////                
////                pendingProvisioning = (provisioningManager, .noOobPublicKey, .noOob)
////                
////                guard let capabilites = provisioningManager.provisioningCapabilities else {
////                    return ["isSuccess": false, "Body": "No provisioning capabilites"]
////                }
////                
////                try provisioningManager.provision(
////                    usingAlgorithm: capabilites.algorithms.strongest,
////                    publicKey: publicKey,
////                    authenticationMethod: authenticationMethod
////                )
//
//                return ["isSuccess": true, "Body": nil]
//            } catch {
//                // プロビジョニングに失敗したらErrorメッセージをそのまま返す
////                print("Error to provisioning")
////                print(error)
//                return ["isSuccess": false, "Body": "Failed to provisioning. \(error)"]
//            }
        } else {
            // unprovisioning deviceにできない（Proxy Nodeとか）場合はError
            return [
                "isSuccess": false,
                "Body": "Failed to recognize as unprovisioned device"
            ]
        }
    }
    func bearerDidOpen(_ bearer: Bearer) {
        print("🟢 Bearer opened successfully")
        print("isOpen:", bearer.isOpen)

        guard let device = pendingDevice else {
            print("No Pending Device")
            return
        }

        guard let provisioningBearer = bearer as? ProvisioningBearer else {
            print("🟥 Could not cast bearer to ProvisioningBearer")
            return
        }

        let manager = self.meshNetworkManager!

        manager.transmitter = provisioningBearer

        do {
            let provisioningManager = try manager.provision(
                unprovisionedDevice: device,
                over: provisioningBearer
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                guard let capabilities = provisioningManager.provisioningCapabilities else {
                    print("🟥 Capabilities are nil")
                    return
                }
                
                do {
                    
                    try provisioningManager.provision(
                        usingAlgorithm: capabilities.algorithms.strongest,
                        publicKey: .noOobPublicKey,
                        authenticationMethod: .noOob
                    )
                } catch {
                    print("\(error)")
                }

                print("Provisioning started")
            }
        } catch {
            print("Failed to start provisioning: \(error)")
        }

        self.pendingProvisioning = nil
    }


    // bearer エラー時
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        print("Bearer closed with error: \(String(describing: error))")
    }
}


extension MeshNetworkManager {
    static var instance: MeshNetworkManager {
        if Thread.isMainThread {
            return (UIApplication.shared.delegate as! AppDelegate).meshNetworkManager
        } else {
            return DispatchQueue.main.sync {
                return (UIApplication.shared.delegate as! AppDelegate).meshNetworkManager
            }
        }
    }
    
    static var bearer: NetworkConnection! {
        if Thread.isMainThread {
            return (UIApplication.shared.delegate as! AppDelegate).connection
        } else {
            return DispatchQueue.main.sync {
                return (UIApplication.shared.delegate as! AppDelegate).connection
            }
        }
    }
}
