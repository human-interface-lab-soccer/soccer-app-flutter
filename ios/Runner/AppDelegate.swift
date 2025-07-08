import Flutter
import NordicMesh
import UIKit
import CoreBluetooth

@main
@objc class AppDelegate: FlutterAppDelegate {

    private var generalBleScanner: GeneralBleScanner?
    private var meshNetworkManager: MeshNetworkManager!

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
    
    func initializeMeshNetwork() -> Void {
        meshNetworkManager = MeshNetworkManager()
        meshNetworkManager.networkParameters = .default
        
        // Setting up Local Node
        // refer to https://nordicsemiconductor.github.io/IOS-nRF-Mesh-Library/documentation/nordicmesh/localnode
        let primaryElement = Element(
            name: "Primary Element",
            location: .first,
            models: [
                Model(sigModelId: .genericOnOffClientModelId, delegate: GenericOnOffClientDelegate()),
            ]
        )
        meshNetworkManager.localElements = [primaryElement]

        // Creating and loading a network configuration
        do {
            if try meshNetworkManager.load() {
//                 meshNetworkDidChange()
            } else {
                _ = meshNetworkManager.createNewMeshNetwork(withName: "My Network", by: "My Provisioner")
                _ = meshNetworkManager.save()
            }
            print("[DEBUG] Successfuly created network configuration!!")
        } catch {
            print(error)
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
        
        // unprovisioning deviceにしてみる
        if let unprovisionedDevice = UnprovisionedDevice(advertisementData: advertisementData) {
            let bearer = PBGattBearer(target: peripheral)
            bearer.dataDelegate = meshNetworkManager
            meshNetworkManager.transmitter = bearer
            bearer.open()
            
            do {
                let provisioningManager = try meshNetworkManager.provision(
                    unprovisionedDevice: unprovisionedDevice,
                    over: bearer
                )

//                print("[Provisioning Manager State]", provisioningManager.state)
//                print("[Provisioning Manager isDeviceSupported]", provisioningManager.isDeviceSupported)
//                print("[Mesh Network]", meshNetworkManager.meshNetwork?.localProvisioner)
//                print(meshNetworkManager.meshNetwork?.meshName)
//                print(meshNetworkManager.meshNetwork?.nodes[0].elements)
//                print(meshNetworkManager.meshNetwork?.nodes)
                print("Probably Success ..!")
                return ["isSuccess": true, "Body": nil]
            } catch {
                // プロビジョニングに失敗したらErrorメッセージをそのまま返す
//                print("Error to provisioning")
//                print(error)
                return ["isSuccess": false, "Body": "Failed to provisioning. \(error)"]
            }
        } else {
            // unprovisioning deviceにできない（Proxy Nodeとか）場合はError
            return [
                "isSuccess": false,
                "Body": "Failed to recognize as unprovisioned device"
            ]
        }
    }
}
