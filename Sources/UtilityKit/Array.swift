//
//  Array.swift
//  
//
//  Created by Maddie Schipper on 3/6/21.
//

import Foundation

extension Array {
    public mutating func reject(where predicate: (Element) throws -> Bool) rethrows {
        try self.removeAll(where: predicate)
    }
    
    public mutating func select(where predicate: (Element) throws -> Bool) rethrows {
        try self.removeAll(where: { try !predicate($0) })
    }
    
    public func rejecting(where predicate: (Element) throws -> Bool) rethrows -> Self {
        var copy = self
        try copy.reject(where: predicate)
        return copy
    }
    
    public func selecting(where predicate: (Element) throws -> Bool) rethrows -> Self {
        var copy = self
        try copy.select(where: predicate)
        return copy
    }
    
    public func count(where predicate: (Element) throws -> Bool) rethrows -> Int {
        return try self.selecting(where: predicate).count
    }
}
