//
//  GenericColorSetUnackowleged.swift
//  Runner
//
//  Created by lights Winner on 2025/09/18.
//

import Foundation
import NordicMesh

public struct GenericColorSetUnacknowleged: StaticUnacknowledgedMeshMessage,
    TransactionMessage, TransitionMessage
{
    public static let opCode: UInt32 = 0x8203

    public var tid: UInt8!
    public var parameters: Data? {
        let data = Data() + color + color2 + color3 + tid
        if let transitionTime = transitionTime, let delay = delay {
            return data + transitionTime.rawValue + delay
        } else {
            return data
        }
    }

    // The new state of Generic OnOff Server.
    public let color: UInt16
    public let color2: UInt16
    public let color3: UInt16

    public let transitionTime: TransitionTime?
    public let delay: UInt8?

    /// Creates the Generic OnOff Set Unacknowledged message.
    ///
    /// - parameter isOn: The target value of the Generic OnOff state.
    public init(_ color: UInt16, color2: UInt16, color3: UInt16) {
        self.color = color
        self.color2 = color2
        self.color3 = color3
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
        _ color: UInt16,
        color2: UInt16,
        color3: UInt16,
        transitionTime: TransitionTime,
        delay: UInt8
    ) {
        self.color = color
        self.color2 = color2
        self.color3 = color3
        self.transitionTime = transitionTime
        self.delay = delay
    }

    public init?(parameters: Data) {
        guard parameters.count == 7 || parameters.count == 9 else {
            return nil
        }
        color = parameters.read(fromOffset: 0)
        color2 = parameters.read(fromOffset: 2)
        color3 = parameters.read(fromOffset: 4)
        tid = parameters[6]
        if parameters.count == 9 {
            transitionTime = TransitionTime(rawValue: parameters[7])
            delay = parameters[8]
        } else {
            transitionTime = nil
            delay = nil
        }
    }
}
