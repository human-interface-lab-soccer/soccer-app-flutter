//
//  VendorColorSet.swift
//  Runner
//

import Foundation
import NordicMesh

public struct VendorColorSet: StaticAcknowledgedVendorMessage {
    public static let opCode: UInt32 = 0xC15900
    public static let responseType: StaticMeshResponse.Type = VendorColorStatus.self

    public var parameters: Data? {
        return Data(colors)
    }

    public let colors: [UInt8]

    public init(colors: [UInt8]) {
        self.colors = colors
    }

    public init?(parameters: Data) {
        guard parameters.count == 12 else { return nil }
        self.colors = Array(parameters)
    }
}
