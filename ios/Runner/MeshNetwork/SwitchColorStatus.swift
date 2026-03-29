//
//  SwitchColorStatus.swift
//  Runner
//
//  Created by naokeyn on 2025/11/11.
//

import Foundation
import NordicMesh

public struct SwitchColorStatus: StaticMeshMessage,
    StaticMeshResponse,
    TransitionStatusMessage
{

    public static let opCode: UInt32 =
        UInt32(
            UInt32(0x01 << 16) | UInt32(0xC00000)
                | UInt32(UInt16.customCompanyID)
        )

    public var parameters: Data? {
        let data = Data([colorNum])
        if let targetState = targetState, let remainingTime = remainingTime {
            return data + UInt8(targetState) + remainingTime.rawValue
        } else {
            return data
        }
    }

    public let colorNum: UInt8
    public let targetState: UInt8?
    public let remainingTime: TransitionTime?

    public init(_ colorNum: UInt8) {
        self.colorNum = colorNum
        //        self.colorNum2 = colorNum2
        //        self.colorNum3 = colorNum3
        self.targetState = nil
        self.remainingTime = nil
    }

    public init?(parameters: Data) {
        guard parameters.count == 1 || parameters.count == 3 else {
            return nil
        }
        colorNum = parameters[0]
        if parameters.count == 3 {
            targetState = parameters[1]
            remainingTime = TransitionTime(rawValue: parameters[2])
        } else {
            targetState = nil
            remainingTime = nil
        }
    }
}
