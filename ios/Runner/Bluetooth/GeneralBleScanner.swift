//
//  GeneralScanner.swift
//  Runner
//
//  Created by naokeyn on 2025/06/26.
//
import Flutter
import CoreBluetooth

/// テスト用の汎用Bluetoothスキャナクラス
class GeneralBleScanner: NSObject, CBCentralManagerDelegate {

    private var centralManager: CBCentralManager!
    private var eventSink: FlutterEventSink?
    var devices: [String] = []

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        print("汎用スキャンを開始します...")
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("BluetoothがONになっていません。state: \(centralManager.state.rawValue)")
        }
    }

    func stopScan() {
        print("汎用スキャンを停止します。")
        centralManager.stopScan()
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("汎用スキャナ: Bluetoothの状態が変化 -> \(central.state.rawValue)")
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
        print(
            "[DEBUG] Found device -> Device: \(deviceName), UUID: \(deviceId), RSSI: \(RSSI.intValue)"
        )
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
