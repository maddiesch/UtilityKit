//
//  ResourcePool.swift
//  
//
//  Created by Maddie Schipper on 4/27/21.
//

import Foundation

public final class ResourcePool<Resource> {
    public enum TimeoutError : Swift.Error {
        case waitTimeout
    }
    
    private class ResourceInstance<Resource> {
        fileprivate let resource: Resource
        fileprivate var available: Bool = true
        fileprivate var lastCheckout = DispatchTime.now()
        
        fileprivate init(_ resource: Resource) {
            self.resource = resource
        }
    }
    
    public let provider: () -> Resource
    
    private let semaphore: DispatchSemaphore
    
    private var resources: [ResourceInstance<Resource>] = []
    
    private let providerMutex = Mutex()
    
    public init(size: Int, provider: @escaping () -> Resource) {
        precondition(size > 0, "Resource pool size must be greater than zero")
        
        self.semaphore = DispatchSemaphore(value: Int(size))
        self.provider = provider
    }
    
    public func with<T>(_ block: (Resource) throws -> T) rethrows -> T {
        self.semaphore.wait()
        
        defer { self.semaphore.signal() }
        
        self.providerMutex.lock()
        let container = self.provideResource()
        container.available = false
        container.lastCheckout = .now()
        self.providerMutex.unlock()
        
        defer {
            self.providerMutex.lock()
            container.available = true
            self.providerMutex.unlock()
        }
        
        return try block(container.resource)
    }
    
    private func provideResource() -> ResourceInstance<Resource> {
        if let existing = self.resources.first(where: \.available) {
            return existing
        }
        
        let newResource = ResourceInstance(self.provider())
        
        self.resources.append(newResource)
        
        return newResource
    }
}
