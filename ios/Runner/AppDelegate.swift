import Flutter
import NordicMesh
import UIKit

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
        let generalBleScanner = FlutterEventChannel(
            name: "human.mech.saitama-u.ac.jp/generalBleScanner",
            binaryMessenger: controller.binaryMessenger
        )
        let scanner = GeneralBleScanner()
        generalBleScanner.setStreamHandler(
            scanner
        )
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
