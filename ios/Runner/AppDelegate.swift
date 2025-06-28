import Flutter
import NordicMesh
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    private var generalScanner: GeneralBleScanner?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let generalBleScanner = FlutterEventChannel(
            name: "human.mech.saitama-u.ac.jp/generalBleScanner",
            binaryMessenger: controller.binaryMessenger
        )
        let generalBleScannerMethod = FlutterMethodChannel(
            name: "human.mech.saitama-u.ac.jp/generalBleScannerMethod",
            binaryMessenger: controller.binaryMessenger
        )
        
        generalBleScannerMethod.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
            if call.method == "startScanning" {
                result("[MethodChannel] Start Scanning...")
            } else if call.method == "stopScanning" {
                result("[MethodChannel] Done!")
            } else {
                result(FlutterMethodNotImplemented)
                return;
            }
            return;
        })
        
        let scanner = GeneralBleScanner()
        generalBleScanner.setStreamHandler(
            scanner
        )
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
