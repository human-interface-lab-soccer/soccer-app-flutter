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
//                Model(vendorModelId: .simpleOnOffClientModelId, companyId: .nordicSemiconductorCompanyId, delegate: SimpleOnOffClientDelegate()
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
        
        // Provisioning
//        let unprovisionedDevice: CBPeripheral = generalBleScanner?.discoveredDevices.first
//        let provisioningManager = try meshNetworkManager.provision(
//            unprovisionedDevice: UnprovisionedDevice(uuid: unprovisionedDevice.identifier.uuidString),
//            over: PBGattBearer(target: unprovisionedDevice)
//        )
    }
    
    func provisioning(uuid: CBUUID) -> Void {
        let unprovisionedDevice: CBPeripheral = UnprovisionedDevice(uuid: uuid)
        try {
            meshNetworkManager.provision(unprovisionedDevice: unprovisionedDevice, over: bearer)
        } catch (error) {
            print(error)
        }
    }
}
