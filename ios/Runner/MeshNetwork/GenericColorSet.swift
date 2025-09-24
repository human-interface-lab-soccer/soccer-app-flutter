//
//  GenericColorSet.swift
//  Runner
//
//  Created by naokeyn on 2025/09/18.
//

import Foundation
import NordicMesh

public struct GenericColorSet: StaticAcknowledgedMeshMessage,
    TransactionMessage,
    TransitionMessage
{
    public static let opCode: UInt32 = 0x8202
    public static let responseType: StaticMeshResponse.Type = GenericColorStatus
        .self

    public var tid: UInt8!
    public var parameters: Data? {
        let data = Data() + phase + color + color2 + tid
        if let color3 = color3, let color4 = color4, let color5 = color5,
            let transitionTime = transitionTime, let delay = delay
        {
            return data + color3 + color4 + color5 + transitionTime.rawValue
                + delay
        } else {
            return data
        }
    }

    // The new state of Generic OnOff Server.
    public let phase: UInt16
    public let color: UInt16
    public let color2: UInt16
    public let color3: UInt16?
    public var color4: UInt16?
    public let color5: UInt16?

    public let transitionTime: TransitionTime?
    public let delay: UInt8?

    /// Creates the Generic OnOff Set Unacknowledged message.
    ///
    /// - parameter isOn: The target value of the Generic OnOff state.
    public init(_ phase: UInt16, color: UInt16, color2: UInt16) {
        self.phase = phase
        self.color = color
        self.color2 = color2
        self.color3 = nil
        self.color4 = nil
        self.color5 = nil
        self.transitionTime = nil
        self.delay = nil
    }

    /// Creates the Generic OnOff Set Unacknowledged message.
    ///
    /// - parameters:
    ///   - isOn: The target value of the Generic OnOff state.
    ///   - transitionTime: The time that an element will take to transition
    ///                     to the target state from the present state.
    ///   - delay: Message execution delay in 5 millisecond steps.
    public init(
        _ phase: UInt16,
        color: UInt16,
        color2: UInt16,
        color3: UInt16,
        color4: UInt16,
        color5: UInt16,
        transitionTime: TransitionTime,
        delay: UInt8
    ) {
        self.phase = phase
        self.color = color
        self.color2 = color2
        self.color3 = color3
        self.color4 = color4
        self.color5 = color5
        self.transitionTime = transitionTime
        self.delay = delay
    }

    public init?(parameters: Data) {
        guard parameters.count == 7 || parameters.count == 15 else {
            return nil
        }
        phase = parameters.read(fromOffset: 0)
        color = parameters.read(fromOffset: 2)
        color2 = parameters.read(fromOffset: 4)
        tid = parameters[6]
        if parameters.count == 15 {
            color3 = parameters.read(fromOffset: 7)
            color4 = parameters.read(fromOffset: 9)
            color5 = parameters.read(fromOffset: 11)
            transitionTime = TransitionTime(rawValue: parameters[13])
            delay = parameters[14]
        } else {
            color3 = nil
            color4 = nil
            color5 = nil
            transitionTime = nil
            delay = nil
        }
    }

}
