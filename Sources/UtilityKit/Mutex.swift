//
//  Mutex.swift
//  
//
//  Created by Maddie Schipper on 3/22/21.
//

import Foundation

public final class Mutex {
    public struct Attribute {
        public static let normal = Attribute(rawValue: PTHREAD_MUTEX_NORMAL)
        public static let recursive = Attribute(rawValue: PTHREAD_MUTEX_RECURSIVE)
        
        public let rawValue: Int32
        
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
    }
    
    private var mutex = pthread_mutex_t()
    
    public init(attribute: Attribute = .normal) {
        var attr = pthread_mutexattr_t()
        
        guard pthread_mutexattr_init(&attr) == 0 else {
            fatalError("Failed to initialize mutex attribute")
        }
        
        defer {
            pthread_mutexattr_destroy(&attr)
        }
        
        guard pthread_mutexattr_settype(&attr, attribute.rawValue) == 0 else {
            fatalError("Failed to set attribute type")
        }
        
        switch pthread_mutex_init(&mutex, &attr) {
        case 0:
            break // Success
        case EAGAIN:
            fatalError("Failed to initialize mutex \"EAGAIN\" -- Lack of system resources")
        case EINVAL:
            fatalError("Failed to initialize mutex \"EINVAL\" -- Invalid attribute")
        case ENOMEM:
            fatalError("Failed to initialize mutex \"ENOMEM\" -- Out of memory")
        default:
            fatalError("Failed to initialized mutex with unknown error")
        }
    }
    
    deinit {
        assert(pthread_mutex_trylock(&mutex) == 0 && pthread_mutex_unlock(&mutex) == 0, "Unable to destroy a locked mutex")
        
        pthread_mutex_destroy(&mutex)
    }
    
    public func lock() {
        switch pthread_mutex_lock(&mutex) {
        case 0:
            break // success
        case EDEADLK:
            fatalError("Failed to acquire lock. A deadlock would have occurred")
        case EINVAL:
            fatalError("Failed to acquire lock. The mutex is invalid")
        default:
            fatalError("Failed to obtain lock with unspecified error")
        }
    }
    
    public func unlock() {
        switch pthread_mutex_unlock(&mutex) {
        case 0:
            break // success
        case EPERM:
            fatalError("Failed to release lock. The unlocking thread does not hold the mutex")
        case EINVAL:
            fatalError("Failed to release lock. The mutex is invalid")
        default:
            fatalError("Could not unlock mutex with unspecified error")
        }
    }
}

extension Mutex : NSLocking, Synchronized {}

public protocol Synchronized {
    func synchronized<T>(block: () throws -> T) rethrows -> T
}

extension Synchronized where Self : NSLocking {
    public func synchronized<T>(block: () throws -> T) rethrows -> T {
        self.lock()
        defer { self.unlock() }
        
        return try block()
    }
}

extension DispatchQueue : Synchronized {
    public func synchronized<T>(block: () throws -> T) rethrows -> T {
        return try self.sync(flags: .barrier) {
            return try block()
        }
    }
}

@propertyWrapper public struct Atomic<Object> {
    private let lock: Synchronized
    
    private var _wrappedValue: Object
    
    public var wrappedValue: Object {
        get {
            self.lock.synchronized { self._wrappedValue }
        }
        set {
            self.lock.synchronized {
                self._wrappedValue = newValue
            }
        }
    }
    
    public init(_ lock: Synchronized,  wrappedValue: Object) {
        self.lock = lock
        self._wrappedValue = wrappedValue
    }
}
