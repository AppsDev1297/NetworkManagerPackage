//
//  NetworkReachability.swift
//  NetworkManager
//
//  Created by aman.gupta on 30/07/25.
//

import Foundation
import Network
import Combine

// An enum to handle the network status
public enum NetworkStatus: String {
    case connected
    case disconnected
}

// An enum to check the network type
public enum NetworkType: String {
    case wifi
    case cellular
    case wiredEthernet
    case other
}

public class NetworkReachability : @unchecked Sendable {
    
    public static let sharedInstance = NetworkReachability()
    
    //MARK: Variables
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    //MARK: Publishers
    @Published public var status: NetworkStatus = .connected
    @Published public private(set) var isConnected: Bool = true
    @Published private var pathStatus = NWPath.Status.requiresConnection
    
    private init() {
        monitorNetwork()
    }
    
    //MARK: Detect Network Type
    public var networkType: NetworkType? {
        let type = monitor.currentPath.availableInterfaces.filter {
            monitor.currentPath.usesInterfaceType($0.type) }.first?.type
        return getNetworkType(interFaceType: type)
    }
    
    //MARK: Monitor Network Status
    private func monitorNetwork() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            if self.pathStatus != path.status {
                self.pathStatus = path.status
                self.isConnected = path.status == .satisfied
                self.status = self.pathStatus == .satisfied ? .connected : .disconnected
            }
        }
        monitor.start(queue: queue)
    }
    
    //MARK: Stop Monitoring Network Status
    public func stopMonitoring() {
        monitor.cancel()
    }
    
    //MARK: Get Network Type ie WIFI, CELLULAR, WIRED NETWORK
    private func getNetworkType(interFaceType: NWInterface.InterfaceType?) -> NetworkType {
        switch interFaceType {
        case .wifi:
            return .wifi
        case .cellular:
            return .cellular
        case .wiredEthernet:
            return .wiredEthernet
        default:
            return .other
        }
    }
}
