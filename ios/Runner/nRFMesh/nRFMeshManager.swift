//
//  nRFMeshManager.swift
//  Runner
//
//  Created by naokeyn on 2025/06/24.
//
import Flutter

//@UIApplicationMain
//@objc class MeshManager: FlutterAppDelegate {
//    override func application(
//        _ application: UIApplication,
//        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//    ) -> Bool {
//        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
//        let nRFMeshChannel = FlutterMethodChannel(
//            name: "human.mech.saitama-u.ac.jp/nRFMesh",
//            binaryMessenger: controller.binaryMessenger
//        )
//        
//        nRFMeshChannel.setMethodCallHandler({
//            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
//            
//            guard call.method == "scanMeshNodes" else {
//                result(FlutterMethodNotImplemented)
//                return
//            }
//            self?.scanMeshNodes(result: result)
//        })
//        
//        GeneratedPluginRegistrant.register(with: self)
//        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//    }
//    
//    private func scanMeshNodes(result: FlutterResult) {
//         result(["Device-A", "Device-B", "Device-C"])
//    }
//}
