import Flutter
import UIKit
import NordicMesh

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    private var meshNetworkManager: MeshNetworkManager!
    private var connection: NetworkConnection!
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let nRFMeshChannel = FlutterMethodChannel(
            name: "human.mech.saitama-u.ac.jp/nRFMesh",
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
            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
            
            guard call.method == "scanMeshNodes" else {
                result(FlutterMethodNotImplemented)
                return
            }
            self?.scanMeshNodes(result: result)
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func scanMeshNodes(result: FlutterResult) {
        let devices: Array<String> = ["Device-A", "Device-B", "Device-C"]
        let scanDuration: TimeInterval = 5.0
        
        connection.open()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + scanDuration) {
            [weak self] in
            guard let self = self else {return}
            
            print(self.connection.proxies)
            self.connection.close()
            print("Proxies: ", self.connection.proxies)
            print("IsConnected: ", self.connection.isConnected)
            
        }
        
        result(devices)
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
    
    /// Sets up the local Elements and reinitializes the ``NetworkConnection``
    /// so that it starts scanning for devices advertising the new Network ID.
//    func meshNetworkDidChange() {
//        connection?.close()
//        
//        let meshNetwork = meshNetworkManager.meshNetwork!
//
//        // Generic Default Transition Time Server model:
//        let defaultTransitionTimeServerDelegate = GenericDefaultTransitionTimeServerDelegate(meshNetwork)
//        // Scene Server and Scene Setup Server models:
//        let sceneServer = SceneServerDelegate(meshNetwork,
//                                              defaultTransitionTimeServer: defaultTransitionTimeServerDelegate)
//        let sceneSetupServer = SceneSetupServerDelegate(server: sceneServer)
//        
//        // Set up local Elements on the phone.
//        let element0 = Element(name: "Primary Element", location: .first, models: [
//            // Scene Server and Scene Setup Server models (client is added automatically):
//            Model(sigModelId: .sceneServerModelId, delegate: sceneServer),
//            Model(sigModelId: .sceneSetupServerModelId, delegate: sceneSetupServer),
//            // Sensor Client model:
//            Model(sigModelId: .sensorClientModelId, delegate: SensorClientDelegate()),
//            // Generic Power OnOff Client model:
//            Model(sigModelId: .genericPowerOnOffClientModelId, delegate: GenericPowerOnOffClientDelegate()),
//            // Generic Default Transition Time Server model:
//            Model(sigModelId: .genericDefaultTransitionTimeServerModelId,
//                  delegate: defaultTransitionTimeServerDelegate),
//            Model(sigModelId: .genericDefaultTransitionTimeClientModelId,
//                  delegate: GenericDefaultTransitionTimeClientDelegate()),
//            // 4 generic models defined by Bluetooth SIG:
//            Model(sigModelId: .genericOnOffServerModelId,
//                  delegate: GenericOnOffServerDelegate(meshNetwork,
//                                                       defaultTransitionTimeServer: defaultTransitionTimeServerDelegate,
//                                                       elementIndex: 0)),
//            Model(sigModelId: .genericLevelServerModelId,
//                  delegate: GenericLevelServerDelegate(meshNetwork,
//                                                       defaultTransitionTimeServer: defaultTransitionTimeServerDelegate,
//                                                       elementIndex: 0)),
//            Model(sigModelId: .genericOnOffClientModelId, delegate: GenericOnOffClientDelegate()),
//            Model(sigModelId: .genericLevelClientModelId, delegate: GenericLevelClientDelegate()),
//            Model(sigModelId: .lightLCClientModelId, delegate: LightLCClientDelegate()),
//            // Nordic Pairing Initiator model:
//            Model(vendorModelId: .lePairingInitiator,
//                  companyId: .nordicSemiconductorCompanyId,
//                  delegate: PairingInitiatorDelegate()),
//            // A simple vendor model:
//            Model(vendorModelId: .simpleOnOffClientModelId,
//                  companyId: .nordicSemiconductorCompanyId,
//                  delegate: SimpleOnOffClientDelegate())
//        ])
//        let element1 = Element(name: "Secondary Element", location: .second, models: [
//            Model(sigModelId: .genericOnOffServerModelId,
//                  delegate: GenericOnOffServerDelegate(meshNetwork,
//                                                       defaultTransitionTimeServer: defaultTransitionTimeServerDelegate,
//                                                       elementIndex: 1)),
//            Model(sigModelId: .genericLevelServerModelId,
//                  delegate: GenericLevelServerDelegate(meshNetwork,
//                                                       defaultTransitionTimeServer: defaultTransitionTimeServerDelegate,
//                                                       elementIndex: 1)),
//            Model(sigModelId: .genericOnOffClientModelId, delegate: GenericOnOffClientDelegate()),
//            Model(sigModelId: .genericLevelClientModelId, delegate: GenericLevelClientDelegate())
//        ])
//        meshNetworkManager.localElements = [element0, element1]
//        
//        connection = NetworkConnection(to: meshNetwork)
//        connection!.dataDelegate = meshNetworkManager
//        connection!.logger = self
//        meshNetworkManager.transmitter = connection
//        connection!.open()
//    }
}
