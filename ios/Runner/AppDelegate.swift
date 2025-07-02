import Flutter
import NordicMesh
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    private var generalBleScanner: GeneralBleScanner?

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
}
