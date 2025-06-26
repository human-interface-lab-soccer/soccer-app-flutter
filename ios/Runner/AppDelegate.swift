import Flutter
import UIKit
import NordicMesh
import CoreBluetooth

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
            self?._scanMeshNodes(result: result)
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
    
    private func _scanMeshNodes(result: FlutterResult) {
        generalScanner = GeneralBleScanner()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.generalScanner?.stopScan()
            self?.generalScanner = nil
        }
        
        result(["テスト完了"])
    }
}

/// テスト用の汎用Bluetoothスキャナクラス
class GeneralBleScanner: NSObject, CBCentralManagerDelegate {
    
    private var centralManager: CBCentralManager!
    
    override init() {
        super.init()
        // CBCentralManagerを初期化し、イベントの通知先をこのクラスに設定
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // スキャンを開始するメソッド
    func startScan() {
        print("汎用スキャンを開始します...")
        // BluetoothがONになっていればスキャンを開始する
        if centralManager.state == .poweredOn {
            // withServices: nil にすることで、全てのBLEデバイスをスキャン対象にする
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("BluetoothがONになっていません。state: \(centralManager.state.rawValue)")
        }
    }
    
    // スキャンを停止するメソッド
    func stopScan() {
        print("汎用スキャンを停止します。")
        centralManager.stopScan()
    }
    
    // Bluetoothの状態が変化したときに呼ばれるメソッド
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("汎用スキャナ: Bluetoothの状態が変化 -> \(central.state.rawValue)")
        if central.state == .poweredOn {
            // BluetoothがONになったら、スキャンを再試行する
            startScan()
        }
    }
    
    // デバイスを発見するたびに呼ばれるメソッド
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // peripheral.nameがnilでなければ、その名前を出力する
        if let deviceName = peripheral.name {
            print("デバイス発見！ -> Name: \(deviceName), RSSI: \(RSSI)")
        }
    }
}
