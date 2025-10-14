//
//  GenericColorClientDelegate.swift
//  Runner
//
//  Created by naokeyn on 2025/10/12.
//

import Foundation
import NordicMesh

class GenericColorClientDelegate: ModelDelegate {

    let messageTypes: [UInt32: MeshMessage.Type]
    let isSubscriptionSupported: Bool = true

    var publicationMessageComposer: MessageComposer? {
        func compose() -> MeshMessage {
            return GenericColorSetUnacknowleged(
                self.state[0],
                color2: self.state[1],
                color3: self.state[2]
            )
        }
        let request = compose()
        return {
            return request
        }
    }

    var state: [UInt16] = [UInt16(0000), UInt16(0000), UInt16(0000)] {
        didSet {
            publish(using: MeshNetworkManager.instance)
        }
    }

    init() {
        let types: [StaticMeshMessage.Type] = [
            GenericColorStatus.self
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
        // The status message may be received here if the Generic OnOff Server model
        // has been configured to publish. Ignore this message.
    }

    func model(
        _ model: Model,
        didReceiveResponse response: MeshResponse,
        toAcknowledgedMessage request: AcknowledgedMeshMessage,
        from source: Address
    ) {
        // Ignore.
    }

}

// GenericColorのModelIDを設定
extension UInt16 {
    public static let genericColorServerModelID: UInt16 = 0xffff
    public static let genericColorClientModelID: UInt16 = 0xfffe
}
