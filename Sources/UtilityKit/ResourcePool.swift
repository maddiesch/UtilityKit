//
//  ResourcePool.swift
//  
//
//  Created by Maddie Schipper on 4/27/21.
//

import Foundation

/// ResourcePool provides a thread-safe pool that can provide a finite number of resources
/// Resources are created lazily as needed so if only one thread needs access to the resources then only one resource will be created.
///
/// Thread-safety is not guaranteed for the resource, only the vending of resources.
public final class ResourcePool<Resource> {
    public typealias Provider = () throws -> Resource
    
    private let provider: Provider
    private let semaphore: DispatchSemaphore
    private let providerQueue: DispatchQueue
    private var resources: [Resource]
    
    /// Create a new ResourcePool
    /// - Parameters:
    ///   - size: The maximum number of resources that will be vended by the pool
    ///   - provider: The closure that provides the resources on demand. The closure will be called on a serial internal managment queue.
    public init(size: UInt, provider: @escaping Provider) {
        self.semaphore = DispatchSemaphore(value: Int(size))
        self.provider = provider
        self.providerQueue = DispatchQueue(label: "dev.schipper.UtilityKit.ResourcePool_\(String(describing: Resource.self))")
        self.resources = []
    }
    
    public func with<T>(_ block: (Resource) throws -> T) rethrows -> T {
        let resource = self.checkout()
        
        defer {
            self.checkin(resource: resource)
        }
        
        return try block(resource)
    }
    
    public func tryWith<T>(_ block: (Resource) throws -> T) throws -> T {
        let resource = try self.tryCheckout()
        
        defer {
            self.checkin(resource: resource)
        }
        
        return try block(resource)
    }
    
    /// Checks out a resource from the avilable resources. If there are no available resources it will block until one becomes available.
    /// If a resource must be created it "unsafely" calls the provider without error handling.
    /// - Returns: A Resource
    @inlinable
    public func checkout() -> Resource {
        return try! self.tryCheckout()
    }
    
    /// Checks out a resource from the avilable resources. If there are no available resources it will block until one becomes available.
    /// - Throws: Errors thrown by the provider if a resource is created
    /// - Returns: A Resource
    public func tryCheckout() throws -> Resource {
        self.semaphore.wait()
        
        return try self.providerQueue.sync {
            if self.resources.count > 0 {
                return self.resources.removeFirst()
            }
            
            return try self.provider()
        }
    }
    
    /// Returns the given resource to the pool of available resources
    /// - Parameter resource: The resource to return and make available to other consumers
    public func checkin(resource: Resource) {
        self.providerQueue.sync {
            self.resources.append(resource)
        }
        self.semaphore.signal()
    }
}
