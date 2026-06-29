//
//  VendorColorClientDelegate.swift
//  Runner
//

import Foundation
import NordicMesh

class VendorColorClientDelegate: ModelDelegate {

    let messageTypes: [UInt32: MeshMessage.Type]
    let isSubscriptionSupported: Bool = true

    var publicationMessageComposer: MessageComposer? {
        func compose() -> MeshMessage {
            return VendorColorSet(colors: self.state)
        }
        let request = compose()
        return {
            return request
        }
    }

    var state: [UInt8] = Array(repeating: 0, count: 12) {
        didSet {
            publish(using: MeshNetworkManager.instance)
        }
    }

    init() {
        let types: [StaticMeshMessage.Type] = [
            VendorColorStatus.self
        ]
        messageTypes = types.toMap()
    }

    // MARK: - Message handlers

    func model(
        _ model: Model,
        didReceiveAcknowledgedMessage request: AcknowledgedMeshMessage,
        from source: Address,
        sentTo destination: MeshAddress
    ) -> MeshResponse {
        fatalError("Not possible")
    }

    func model(
        _ model: Model,
        didReceiveUnacknowledgedMessage message: UnacknowledgedMeshMessage,
        from source: Address,
        sentTo destination: MeshAddress
    ) {
        // Ignore
    }

    func model(
        _ model: Model,
        didReceiveResponse response: MeshResponse,
        toAcknowledgedMessage request: AcknowledgedMeshMessage,
        from source: Address
    ) {
        // Ignore
    }
}
