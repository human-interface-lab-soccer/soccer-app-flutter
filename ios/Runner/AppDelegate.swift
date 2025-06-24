import Flutter
import UIKit
import NordicMesh

@main
@objc class MeshManager: FlutterAppDelegate {
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

//@objc class AppDelegate: FlutterAppDelegate {
//  override func application(
//    _ application: UIApplication,
//    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//  ) -> Bool {
//
//    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
//    let batteryChannel = FlutterMethodChannel(
//      name: "human.mech.saitama-u.ac.jp/battery",
//      binaryMessenger: controller.binaryMessenger)
//    batteryChannel.setMethodCallHandler({
//      [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
//      // This method is invoked on the UI thread.
//      guard call.method == "getBatteryLevel" else {
//        result(FlutterMethodNotImplemented)
//        return
//      }
//      self?.receiveBatteryLevel(result: result)
//    })
//
//    GeneratedPluginRegistrant.register(with: self)
//    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//  }
//
//  private func receiveBatteryLevel(result: FlutterResult) {
//    let device = UIDevice.current
//    device.isBatteryMonitoringEnabled = true
//    if device.batteryState == UIDevice.BatteryState.unknown {
//      result(
//        FlutterError(
//          code: "UNAVAILABLE",
//          message: "Battery level not available.",
//          details: nil))
//    } else {
//      result(Int(device.batteryLevel * 100))
//    }
//  }
//}
