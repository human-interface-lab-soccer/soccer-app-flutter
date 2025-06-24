import Flutter
import UIKit
import NordicMesh

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    private var meshNetworkManager: MeshNetworkManager?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let nRFMeshChannel = FlutterMethodChannel(
            name: "human.mech.saitama-u.ac.jp/nRFMesh",
            binaryMessenger: controller.binaryMessenger
        )
        
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
        result(devices)
    }
}
