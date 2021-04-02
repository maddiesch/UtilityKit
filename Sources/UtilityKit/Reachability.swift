//
//  Reachability.swift
//  
//
//  Created by Maddie Schipper on 3/19/21.
//

import Foundation
import SystemConfiguration
import Combine

public enum IPAddress {
    case IPv4(in_addr)
    case IPv6(in6_addr, Int32)
    
    public static let v4_zero = IPAddress.IPv4(in_addr())
    
    public static let v6_zero = IPAddress.IPv6(in6_addr(), 0)
    
    public static let localhost = IPAddress.IPv4(in_addr(s_addr: UInt32(0x7f_00_00_01).bigEndian))
}

extension IPAddress : CustomStringConvertible {
    public var description: String {
        let convert = { (ptr: UnsafeRawPointer, family: CInt, len: Int32) -> String in
            var buffer = Array<CChar>(repeating: 0, count: Int(len))
            inet_ntop(family, ptr, &buffer, socklen_t(len))
            return String(cString: buffer)
        }
        switch self {
        case .IPv4(let ip4):
            return withUnsafePointer(to: ip4) {
                convert($0, AF_INET, INET_ADDRSTRLEN)
            }
        case .IPv6(let ip6, let scope):
            let des = withUnsafePointer(to: ip6) {
                convert($0, AF_INET6, INET6_ADDRSTRLEN)
            }
            return scope == 0 ? des : "\(des)%\(scope)"
        }
    }
}

public final class Reachability {
    public enum Error : Swift.Error {
        case nullReachability
        case callbackSetupFailure
        case callbackQueueFailure
    }
    
    public enum Source {
        case host(String)
        case ip(IPAddress)
    }
    
    public enum Status {
        case undetermined
        case unreachable
        case reachableWiFi
        case reachableCellular
        case reachableLocally
        
        public var isActive: Bool {
            switch self {
            case .undetermined:
                return false
            case .unreachable, .reachableWiFi, .reachableCellular, .reachableLocally:
                return true
            }
        }
        
        public var isReachable: Bool {
            switch self {
            case .undetermined, .unreachable:
                return false
            case .reachableWiFi, .reachableCellular, .reachableLocally:
                return true
            }
        }
    }
    
    public convenience init(source: Source) throws {
        switch source  {
        case .host(let host):
            let ref = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, host)
            self.init(ref)
        case .ip(let ip):
            switch ip {
            case .IPv4(let addr):
                var s_addr = sockaddr_in()
                s_addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
                s_addr.sin_family = sa_family_t(AF_INET)
                s_addr.sin_addr = addr
                
                let ref = withUnsafePointer(to: &s_addr) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, $0)
                    }
                }
                
                self.init(ref)
            case .IPv6(let addr, let scope):
                var s_addr = sockaddr_in6()
                s_addr.sin6_len = UInt8(MemoryLayout<sockaddr_in6>.size)
                s_addr.sin6_family = sa_family_t(AF_INET6)
                s_addr.sin6_addr = addr
                s_addr.sin6_scope_id = __uint32_t(scope)
                
                let ref = withUnsafePointer(to: &s_addr) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, $0)
                    }
                }
                self.init(ref)
            }
        }
    }
    
    private var reachability: SCNetworkReachability?
    
    private var _isRunning: Bool = false
    
    private var _publisher = CurrentValueSubject<Status, Never>(.undetermined)
    
    public var publisher: AnyPublisher<Status, Never> {
        return self._publisher.eraseToAnyPublisher()
    }
    
    public var currentStatus: Status {
        self._publisher.value
    }
    
    public var isRunning: Bool {
        Reachability.queue.sync {
            _isRunning
        }
    }
    
    private var flags: SCNetworkReachabilityFlags? {
        guard let r = self.reachability else {
            return nil
        }
        var flags = SCNetworkReachabilityFlags()
        let status = withUnsafeMutablePointer(to: &flags) {
            SCNetworkReachabilityGetFlags(r, $0)
        }
        return status ? flags : nil
    }
    
    fileprivate static let queue = DispatchQueue(label: ApplicationIdentifier + ".Reachability")
    
    private init(_ reachability: SCNetworkReachability?) {
        self.reachability = reachability
    }
    
    public final func start() throws {
        try Reachability.queue.sync {
            guard self._isRunning == false else {
                return
            }
            guard let reach = self.reachability else {
                throw Error.nullReachability
            }
            
            var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
            context.info = Unmanaged<Reachability>.passUnretained(self).toOpaque()
            
            guard SCNetworkReachabilitySetCallback(reach, reachabilityCallbackHandler, &context) else {
                throw Error.callbackSetupFailure
            }
            guard SCNetworkReachabilitySetDispatchQueue(reach, Reachability.queue) else {
                throw Error.callbackQueueFailure
            }
            
            self._isRunning = true
            
            self.updateFromCallback()
        }
    }
    
    public final func stop() throws {
        Reachability.queue.sync {
            guard self._isRunning == true else {
                return
            }
            guard let reach = self.reachability else {
                return
            }
            
            SCNetworkReachabilitySetCallback(reach, nil, nil)
            SCNetworkReachabilitySetDispatchQueue(reach, nil)
            
            self._isRunning = false
        }
    }
    
    deinit {
        try? self.stop()
    }
    
    fileprivate func updateFromCallback() {
        guard let flags = self.flags else {
            self._publisher.send(.undetermined)
            return
        }
        
        var status = Status.unreachable
        
        if flags.contains(.isLocalAddress) {
            status = .reachableLocally
        } else if flags.contains(.reachable) {
            status = .reachableWiFi
        }
        #if os(iOS)
            if flags.contains(.isWWAN) {
                status = .reachableCellular
            }
        #endif
        
        self._publisher.send(status)
    }
}

fileprivate func reachabilityCallbackHandler(_ reachability: SCNetworkReachability, _ flags: SCNetworkReachabilityFlags, _ unsafeContext: UnsafeMutableRawPointer?) {
    guard let context = unsafeContext else {
        return
    }
    Unmanaged<Reachability>.fromOpaque(context).takeUnretainedValue().updateFromCallback()
}
