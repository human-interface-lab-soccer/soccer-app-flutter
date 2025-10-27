//
//  ModelIdentifiers.swift
//  Runner
//
//  Created by naokeyn on 2025/10/27.
//

import Foundation
import NordicMesh

extension UInt16 {
    public static let customCompanyID: UInt16 = 0xFFFF
    public static let customClientModelID: UInt16 = 0x0000
    public static let customServerModelID: UInt16 = 0x0001
    public static let genericColorServerModelID: UInt16 = 0xffff
    public static let genericColorClientModelID: UInt16 = 0xfffe
}

extension UInt32 {
    public static let customClientModelIdentifier: UInt32 =
        (UInt32(UInt16.customCompanyID) << 16)
        | UInt32(UInt16.customClientModelID)
    public static let customServerModelIdentifier: UInt32 =
        (UInt32(UInt16.customCompanyID) << 16)
        | UInt32(UInt16.customServerModelID)

}
