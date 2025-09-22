//
//  GenericColorStatus.swift
//  
//
//  Created by naokeyn 2025/09/18.
//

import Foundation
import NordicMesh

public struct GenericColorStatus: StaticMeshResponse, TransitionStatusMessage {
    public static var opCode: UInt32 = 0x8204

    public var parameters: Data? {
        let data = Data([color])
        if let targetState = targetState, let remainingTime = remainingTime {
            return data + UInt8(targetState) + remainingTime.rawValue
        } else {
            return data
        }
    }

    /// The present state of Generic OnOff Server.
    public let color: UInt8
    /// The target state of Generic OnOff Server.
    public let targetState: UInt8?

    public let remainingTime: TransitionTime?

    /// Creates the Generic OnOff Status message.
    ///
    /// - parameter isOn: The current value of the Generic OnOff state.
    public init(_ color: UInt8) {
        self.color = color
        self.targetState = nil
        self.remainingTime = nil
    }

    /// Creates the Generic OnOff Status message.
    ///
    /// - parameters:
    ///   - isOn: The current value of the Generic OnOff state.
    ///   - targetState: The target value of the Generic OnOff state.
    ///   - remainingTime: The time that an element will take to transition
    ///                    to the target state from the present state.
    public init(_ color: UInt8, targetState: UInt8, remainingTime: TransitionTime) {
        self.color = color
        self.targetState = targetState
        self.remainingTime = remainingTime
    }

    public init?(parameters: Data) {
        guard parameters.count == 1 || parameters.count == 3 else {
            return nil
        }
        color = parameters[0]
        if parameters.count == 3 {
            targetState = parameters[1]
            remainingTime = TransitionTime(rawValue: parameters[2])
        } else {
            targetState = nil
            remainingTime = nil
        }
    }
}
