//
//  AddressResolver.swift
//  
//
//  Created by Maddie Schipper on 3/22/21.
//

import Foundation
import CFNetwork
import Combine

public enum AddressResolutionError : Error {
    case failedToStartHostResolution(CFStreamError)
    case failedToGetCompletedAddressResolution
}

public typealias ResolvedAddress = (ip: IPAddress, port: in_port_t)

/// Resolve a hostname using DNS
///
/// @return Future publisher that will finish with an array of ip addresses
public func ResolveAddresses(forHost hostname: String, queue: DispatchQueue = DispatchQueue.global(qos: .utility)) -> Future<Array<ResolvedAddress>, Error> {
    return Future { finish in
        queue.async {
            do {
                let result = try resolveAddresses(hostname)
                
                let addresses: Array<ResolvedAddress> = result.map { addr in
                    switch addr.sin_family {
                    case sa_family_t(AF_UNSPEC):
                        return withUnsafePointer(to: addr) { ptr in
                            return ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                                let addr = $0.pointee
                                
                                return withUnsafePointer(to: addr.sa_data) {
                                    $0.withMemoryRebound(to: in_addr.self, capacity: 1) { in_addr_ptr in
                                        return ResolvedAddress(.IPv4(in_addr_ptr.pointee), 0)
                                    }
                                }
                            }
                        }
                    default:
                        fatalError()
                    }
                }
                
                finish(.success(addresses))
            } catch {
                finish(.failure(error))
            }
        }
    }
}

fileprivate func resolveAddresses(_ hostname: String) throws -> Array<sockaddr_in> {
    let host = CFHostCreateWithName(kCFAllocatorDefault, hostname as CFString).takeRetainedValue()
    
    var error = CFStreamError()
    
    guard CFHostStartInfoResolution(host, .addresses, &error) else {
        throw AddressResolutionError.failedToStartHostResolution(error)
    }
    
    var finished: DarwinBoolean = false
    
    guard let addresses = CFHostGetAddressing(host, &finished)?.takeUnretainedValue() as? Array<Data>, finished == true else {
        throw AddressResolutionError.failedToGetCompletedAddressResolution
    }
    
    return addresses.map { unsafeBitCast($0, to: sockaddr_in.self) }
}
