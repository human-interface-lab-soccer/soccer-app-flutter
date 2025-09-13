//
//  MeshNetworkEventStreamHandler.swift
//  Runner
//
//  Created by naokeyn on 2025/09/13.
//

import Flutter

enum MeshNetworkStatus: String {
    case error = "error"
    case success = "success"
    case processing = "processing"
}

class MeshNetworkEventStreamHandler: NSObject, FlutterStreamHandler {
    static let shared = MeshNetworkEventStreamHandler()
    private var eventSink: FlutterEventSink?
    private override init() {}

    func onListen(
        withArguments arguments: Any?,
        eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    func sendEvent(status: MeshNetworkStatus, data: [String: Any]) {
        print("[MeshNetworkEvent] status: \(status), data: \(data)")
        guard let sink = eventSink else { return }
        DispatchQueue.main.async {
            var eventData = data
            eventData["status"] = status.rawValue
            sink(eventData)
        }
    }
}
