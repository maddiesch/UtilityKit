//
//  Cache.swift
//  
//
//  Created by Maddie Schipper on 3/14/21.
//

import Foundation

public final class Cache<KeyType, ValueType> where KeyType : AnyObject, ValueType : AnyObject {
    private let backing = NSCache<KeyType, ValueType>()
    
    public init() {}
    
    public final func object(forKey key: KeyType) -> ValueType? {
        return backing.object(forKey: key)
    }

    public final func setObject(_ obj: ValueType, forKey key: KeyType) {
        return backing.setObject(obj, forKey: key)
    }

    public final func removeObject(forKey key: KeyType) {
        return backing.removeObject(forKey: key)
    }
    
    public final func removeAllObjects() {
        return backing.removeAllObjects()
    }
}

extension Cache {
    public func fetch(objectForKey key: KeyType, default fallback: @autoclosure () -> ValueType?) -> ValueType? {
        if let object = self.object(forKey: key) {
            return object
        }
        
        guard let newObject = fallback() else {
            return nil
        }
        
        self.setObject(newObject, forKey: key)
        
        return newObject
    }
    
    public func fetch(objectForKey key: KeyType, default fallback: @autoclosure () -> ValueType) -> ValueType {
        if let object = self.object(forKey: key) {
            return object
        }
        
        let newObject = fallback()
        
        self.setObject(newObject, forKey: key)
        
        return newObject
    }
}
