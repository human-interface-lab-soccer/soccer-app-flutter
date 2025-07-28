//
//  ProvisioningEventStreamHandler.swift
//  Runner
//
//  Created by naokeyn on 2025/07/28.
//

import Flutter

class ProvisioningEventStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

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

    func sendEvent(status: String, data: [String: Any]) {
        print("[provisioningEvent] status: \(status), data: \(data)")
        guard let sink = eventSink else { return }
        DispatchQueue.main.async {
            var eventData = data
            eventData["status"] = status
            sink(eventData)
        }
    }
}
