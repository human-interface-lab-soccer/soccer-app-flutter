//
//  VendorColorStatus.swift
//  Runner
//

import Foundation
import NordicMesh

public struct VendorColorStatus: StaticVendorMessage, StaticMeshResponse {
    public static let opCode: UInt32 = 0xC35900

    public var parameters: Data? {
        return Data([status])
    }

    public let status: UInt8

    public init(status: UInt8) {
        self.status = status
    }

    public init?(parameters: Data) {
        guard parameters.count == 1 else { return nil }
        self.status = parameters[0]
    }
}
