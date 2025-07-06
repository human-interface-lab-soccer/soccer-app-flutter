//
//  GeneralScanner.swift
//  Runner
//
//  Created by naokeyn on 2025/06/26.
//
import Flutter
import CoreBluetooth
import NordicMesh

/// 汎用Bluetoothスキャナクラス
/// フィルタリングには下記を参照↓
/// https://www.bluetooth.com/wp-content/uploads/Files/Specification/Assigned_Numbers.html
class GeneralBleScanner: NSObject, CBCentralManagerDelegate {

    private let MeshProvisioningServiceUUID = CBUUID(string: "1827")    // 未プロビジョニングデバイス
    private let MeshProxyServiceUUID = CBUUID(string: "1828")           // プロビジョニング済みデバイス
    
    private var centralManager: CBCentralManager!
    private var eventSink: FlutterEventSink?

    // 発見したデバイスを格納するSet
    var discoveredDevices: Set<CBPeripheral> = []
    var messages = [String: Any]()

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        print("MeshProvisioningServiceのスキャンを開始します...")
        if centralManager.state == .poweredOn {
            let scanOptions: [String: Any] = [
                CBCentralManagerScanOptionAllowDuplicatesKey: true
            ]
            centralManager.scanForPeripherals(
                // ここにホワイトリストを記載することでフィルタを適用
                withServices: [MeshProvisioningServiceUUID, MeshProxyServiceUUID],
                options: scanOptions
            )
        } else {
            print("BluetoothがONになっていません。state: \(centralManager.state.rawValue)")
        }
    }

    func stopScan() {
        print("MeshProvisioningServiceのスキャンを停止します。")
        centralManager.stopScan()
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("スキャナ: Bluetoothの状態が変化 -> \(central.state.rawValue)")
        if central.state == .poweredOn {
            startScan()
        }
    }

    func centralManager(
        _ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any], rssi RSSI: NSNumber
    ) {
        let deviceName = peripheral.name ?? "Unknown device"
        let deviceId = peripheral.identifier.uuidString

        discoveredDevices.insert(peripheral)
        messages[deviceId] = advertisementData

        print(
            "[DEBUG] Found device -> Device: \(deviceName), UUID: \(deviceId), RSSI: \(RSSI.intValue) \n",
            "[DEBUG] Advertisement Data: \(advertisementData)"
        )
        print("[DEBUG] デバイスの個数", discoveredDevices.count)

        if let sink = eventSink {
            let deviceData: [String: Any] = [
                "name": deviceName,
                "uuid": deviceId,
                "rssi": RSSI.intValue,
            ]
            sink(deviceData)
        }
    }
}

extension GeneralBleScanner: FlutterStreamHandler {

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
        -> FlutterError?
    {
        self.eventSink = events
        startScan()
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        stopScan()
        self.eventSink = nil
        return nil
    }
}
