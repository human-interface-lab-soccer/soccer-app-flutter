import Flutter
import UIKit
import NordicMesh

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    private var meshNetworkManager: MeshNetworkManager!
    private var connection: NetworkConnection!
    
    private var generalScanner: GeneralBleScanner?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let nRFMeshChannel = FlutterMethodChannel(
            name: "human.mech.saitama-u.ac.jp/nRFMesh",
            binaryMessenger: controller.binaryMessenger
        )
        let generalBleScanner = FlutterEventChannel(
            name: "human.mech.saitama-u.ac.jp/generalBleScanner",
            binaryMessenger: controller.binaryMessenger
        )
        
        meshNetworkManager = MeshNetworkManager()
        meshNetworkManager.networkParameters = .default
        
        do {
            if try meshNetworkManager.load() {
//                meshNetworkDidChange()
            }
             else {
                _ = createNewMeshNetwork()
             }
        } catch {
            print(error)
        }
        
        guard let meshNetwork = meshNetworkManager.meshNetwork else {
            fatalError("Fail to initialize Mesh Network")
        }
        print(meshNetwork)
        
        connection = NetworkConnection(to: meshNetwork)
        
        nRFMeshChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            guard call.method == "scanMeshNodes" else {
                result(FlutterMethodNotImplemented)
                return
            }
            self?.scanMeshNodes(result: result)
        })
        
        let scanner = GeneralBleScanner()
        generalBleScanner.setStreamHandler(
            scanner
        )
        
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

//        meshNetworkDidChange()
        return network
    }
    
    private func scanMeshNodes(result: @escaping FlutterResult) {
        
        let durationScan = 5.0
//        generalScanner = GeneralBleScanner()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + durationScan) { [weak self] in
            result(self?.generalScanner?.devices ?? ["Null"])
            self?.generalScanner?.stopScan()
            self?.generalScanner = nil
        }
    }
}
