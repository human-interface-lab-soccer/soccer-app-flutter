////
////  ProvisioningManager.swift
////  Runner
////
////  Created by naokeyn on 2025/07/18.
////
//
//import Foundation
//import NordicMesh
//
//class ProvisioningHandler {
//    var unprovisionedDevice: UnprovisionedDevice?
//    var bearer: ProvisioningBearer!
//    var previousNode: Node?
//    
//    private var publicKey: PublicKey?
//    private var authenticationMethod: AuthenticationMethod?
//    
//    private var provisioningManager: ProvisioningManager!
//    private var capabilitiesReceived = false
//    
//    
//    /// Starts provisioning process of the device.
//    func startProvisionin() -> (isSuccess: Bool, Body: String) {
//        let manager = MeshNetworkManager.instance
//        
//        do {
//            provisioningManager = try manager.provision(unprovisionedDevice: unprovisionedDevice, over: bearer)
//        } catch {
//            switch error {
//            case MeshNetworkError.nodeAlreadyExist:
//                return (false, "Node already exist")
//            default:
//                return (false, "Error: \(error)")
//            }
//        }
//        
//        guard let capabilities = provisioningManager.provisioningCapabilities else {
//            return (false, "Error to capabilities")
//        }
//        
//        // None of OOB methods are supported
//        // TODO: OOBのサポートを行う（ファームウェア含めて）
//        publicKey = .noOobPublicKey
//        authenticationMethod = .noOob
//
//        if provisioningManager.networkKey == nil {
//            let network = MeshNetworkManager.instance.meshNetwork!
//            let networkKey = try! network.add(networkKey: Data.random128BitKey(), name: "Primary Network Key")
//            provisioningManager.networkKey = networkKey
//        }
//        
//        // Start provisioning
//        do {
//            try provisioningManager.provision(
//                usingAlgorithm: capabilities.algorithms.strongest,
//                publicKey: publicKey,
//                authenticationMethod: authenticationMethod
//            )
//            print(provisioningManager)
//        } catch {
//            print("Failed to provision")
//        }
//    }
//}
