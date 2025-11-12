//
//  SwitchColorSet.swift
//  Runner
//
//  Created by naokeyn on 2025/11/11.
//

import Foundation
import NordicMesh

public struct SwitchColorSet: StaticAcknowledgedMeshMessage,
    TransactionMessage,
    TransitionMessage
{
    public static let opCode: UInt32 =
        UInt32(
            UInt32(0x01 << 16) | UInt32(0xC00000)
                | UInt32(UInt16.customCompanyID)
        )
    public static let responseType: StaticMeshResponse.Type =
        SwitchColorStatus.self

    public var tid: UInt8!
    public var parameters: Data? {
        let data = Data() + colorNum + colorNum2 + colorNum3 + tid
        if let transitionTime = transitionTime, let delay = delay {
            return data + transitionTime.rawValue + delay
        } else {
            return data
        }
    }

    public let colorNum: UInt16
    public let colorNum2: UInt16
    public let colorNum3: UInt16
    public let transitionTime: TransitionTime?
    public let delay: UInt8?

    public init(_ colorNum: UInt16, colorNum2: UInt16, colorNum3: UInt16) {
        self.colorNum = colorNum
        self.colorNum2 = colorNum2
        self.colorNum3 = colorNum3
        self.transitionTime = nil
        self.delay = nil
    }

    public init?(parameters: Data) {
        guard parameters.count == 7 || parameters.count == 5 else {
            return nil
        }
        colorNum = parameters.read(fromOffset: 0)
        colorNum2 = parameters.read(fromOffset: 2)
        colorNum3 = parameters.read(fromOffset: 4)
        transitionTime = nil
        delay = nil
    }
}
