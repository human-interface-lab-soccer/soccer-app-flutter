//
//  ProvisionngService.swift
//  Runner
//
//  Created by naokeyn on 2025/07/28.
//

import CoreBluetooth
import Flutter
import NordicMesh

enum ProvisioningStatus: String {
    case connecting = "connecting"
    case discovering = "discovering"
    case identifying = "identifying"
    case provisioning = "provisioning"
    case complete = "complete"
    case error = "error"
}

class ProvisioningService: NSObject {

    static let attentionTimer: UInt8 = 5

    private weak var meshNetworkManager: MeshNetworkManager?
    private weak var bleScanner: GeneralBleScanner?
    private var _provisioningEventStreamHandler: ProvisioningEventStreamHandler!

    // Provisioning
    private var bearer: ProvisioningBearer?
    private var unprovisionedDevice: UnprovisionedDevice?
    private var provisioningManager: ProvisioningManager?

    init(meshNetworkManager: MeshNetworkManager, bleScanner: GeneralBleScanner)
    {
        self.meshNetworkManager = meshNetworkManager
        self.bleScanner = bleScanner
        self._provisioningEventStreamHandler = ProvisioningEventStreamHandler()
        super.init()
    }

    // MARK: - Public Properties
    
    var provisioningEventStreamHandlerInstance: ProvisioningEventStreamHandler {
        return _provisioningEventStreamHandler
    }

    func startProvisioningProcess(
        for uuid: String,
        result: @escaping FlutterResult
    ) {
        cleanupProvisioning(closeBearer: true)

        guard let deviceInfo = bleScanner?.discoveredDevicesList[uuid],
            let peripheral = deviceInfo["peripheral"] as? CBPeripheral,
            let advertisementData = deviceInfo["advertisementData"]
                as? [String: Any]
        else {
            result([
                "isSuccess": false, "body": "Device not found in scan results.",
            ])
            return
        }

        guard
            let unprovisionedDevice = UnprovisionedDevice(
                advertisementData: advertisementData
            )
        else {
            result([
                "isSuccess": false,
                "body": "The device is not a valid unprovisioned device.",
            ])
            return
        }

        self.unprovisionedDevice = unprovisionedDevice

        let bearer = PBGattBearer(target: peripheral)
        bearer.delegate = self
        bearer.dataDelegate = meshNetworkManager
        self.bearer = bearer

        do {
            try? bearer.open()
            _provisioningEventStreamHandler.sendEvent(
                status: .connecting,
                data: [
                    "message":
                        "Connecting to \(unprovisionedDevice.name ?? "device")..."
                ]
            )
            result([
                "isSuccess": true, "body": "Provisioning process initiated.",
            ])
        } catch {
            cleanupProvisioning()
            result([
                "isSuccess": false,
                "body": "Failed to open bearer: \(error.localizedDescription)",
            ])
        }
    }

    private func startProvisioning() {
        guard let provisioningManager = self.provisioningManager,
            let capabilities = provisioningManager.provisioningCapabilities
        else {
            _provisioningEventStreamHandler.sendEvent(
                status: .error,
                data: [
                    "message":
                        "Cannot start provisioning: capabilities not available."
                ]
            )
            return
        }

        _provisioningEventStreamHandler.sendEvent(
            status: .provisioning,
            data: ["message": "Provisioning..."]
        )

        if provisioningManager.networkKey == nil {
            guard let network = meshNetworkManager?.meshNetwork else { return }

            if let primaryKey = network.networkKeys.first {
                provisioningManager.networkKey = primaryKey
            } else {
                do {
                    let newKey = try network.add(
                        networkKey: Data.random128BitKey(),
                        name: "Primary Network Key"
                    )
                    provisioningManager.networkKey = newKey
                } catch {
                    _provisioningEventStreamHandler.sendEvent(
                        status: .error,
                        data: [
                            "message":
                                "Failed to create network key: \(error.localizedDescription)"
                        ]
                    )
                    return
                }
            }
        }

        do {
            try provisioningManager.provision(
                usingAlgorithm: capabilities.algorithms.strongest,
                publicKey: .noOobPublicKey,
                authenticationMethod: .noOob
            )
        } catch {
            _provisioningEventStreamHandler.sendEvent(
                status: .error,
                data: [
                    "message":
                        "Failed to start provisioning: \(error.localizedDescription)"
                ]
            )
            try? bearer?.close()
        }
    }

    private func cleanupProvisioning(closeBearer: Bool = false) {
        if closeBearer {
            try? self.bearer?.close()
        }
        self.bearer = nil
        self.unprovisionedDevice = nil
        self.provisioningManager = nil
    }
}

// MARK: - GattBearerDelegate

extension ProvisioningService: GattBearerDelegate {
    func bearerDidConnect(_ bearer: Bearer) {
        _provisioningEventStreamHandler.sendEvent(
            status: .connecting,
            data: ["message": "Discovering services..."]
        )
    }

    func bearerDidDiscoverServices(_ bearer: Bearer) {
        _provisioningEventStreamHandler.sendEvent(
            status: .connecting,
            data: ["message": "Initializing..."]
        )
    }

    func bearerDidOpen(_ bearer: Bearer) {
        guard let unprovisionedDevice = self.unprovisionedDevice,
            let provisioningBearer = bearer as? ProvisioningBearer
        else {
            _provisioningEventStreamHandler.sendEvent(
                status: .error,
                data: ["message": "Internal error: Device or bearer invalid."]
            )
            return
        }

        _provisioningEventStreamHandler.sendEvent(
            status: .identifying,
            data: ["message": "Identifying device..."]
        )

        do {
            provisioningManager = try meshNetworkManager?.provision(
                unprovisionedDevice: unprovisionedDevice,
                over: provisioningBearer
            )
            provisioningManager!.delegate = self
            try provisioningManager!.identify(
                andAttractFor: ProvisioningService.attentionTimer
            )
        } catch {
            _provisioningEventStreamHandler.sendEvent(
                status: .error,
                data: [
                    "message":
                        "Provisioning setup failed: \(error.localizedDescription)"
                ]
            )
            try? self.bearer?.close()
        }
    }

    func bearer(_ bearer: Bearer, didClose error: Error?) {
        guard let state = provisioningManager?.state else {
            _provisioningEventStreamHandler.sendEvent(
                status: .error,
                data: ["message": "Device disconnected."]
            )
            cleanupProvisioning()
            print("Fail to connect")
            return
        }

        if case .complete = state {
            if meshNetworkManager?.save() ?? false {
                guard
                    let node = meshNetworkManager?.meshNetwork?.node(
                        for: self.unprovisionedDevice!
                    )
                else {
                    _provisioningEventStreamHandler.sendEvent(
                        status: .error,
                        data: ["message": "Provisioned node not found."]
                    )
                    cleanupProvisioning()
                    return
                }
                _provisioningEventStreamHandler.sendEvent(
                    status: .complete,
                    data: [
                        "message": "Provisioning complete!",
                        "nodeUuid": node.uuid.uuidString,
                        "unicastAddress": node.primaryUnicastAddress as Any,  // UnicastAddress? の型を考慮
                    ]
                )
            } else {
                _provisioningEventStreamHandler.sendEvent(
                    status: .error,
                    data: [
                        "message": "Failed to save mesh network configuration."
                    ]
                )
            }
        } else {
            _provisioningEventStreamHandler.sendEvent(
                status: .error,
                data: [
                    "message":
                        "Disconnected: \(error?.localizedDescription ?? "Unknown reason")"
                ]
            )
        }
        cleanupProvisioning()
    }
}

// MARK: - ProvisioningDelegate

extension ProvisioningService: ProvisioningDelegate {
    func provisioningState(
        of unprovisionedDevice: UnprovisionedDevice,
        didChangeTo state: ProvisioningState
    ) {
        DispatchQueue.main.async {
            switch state {
            case .requestingCapabilities:
                self._provisioningEventStreamHandler.sendEvent(
                    status: .identifying,
                    data: ["message": "Requesting capabilities..."]
                )

            case let .capabilitiesReceived(capabilities):
                let capsData: [String: Any] = [
                    "numberOfElements": capabilities.numberOfElements,
                    "algorithms": "\(capabilities.algorithms)",
                    "publicKeyType": "\(capabilities.publicKeyType)",
                    "oobType": "\(capabilities.oobType)",
                    "message": "Capabilities received!",
                ]
                self._provisioningEventStreamHandler.sendEvent(
                    status: .identifying,
                    data: capsData
                )
                self.startProvisioning()

            case .complete:
                self._provisioningEventStreamHandler.sendEvent(
                    status: .provisioning,
                    data: ["message": "Finalizing..."]
                )
            case let .failed(error):
                self._provisioningEventStreamHandler.sendEvent(
                    status: .error,
                    data: [
                        "message":
                            "Provisioning failed: \(error.localizedDescription)"
                    ]
                )
                try? self.bearer?.close()

            default:
                break
            }
        }
    }

    func authenticationActionRequired(_ action: AuthAction) {
        _provisioningEventStreamHandler.sendEvent(
            status: .error,
            data: ["message": "Authentication required but not supported."]
        )
        try? bearer?.close()
    }

    func inputComplete() {
        _provisioningEventStreamHandler.sendEvent(
            status: .provisioning,
            data: ["message": "Input complete. Provisioning..."]
        )
    }
}
