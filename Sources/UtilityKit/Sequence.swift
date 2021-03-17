//
//  Sequence.swift
//  
//
//  Created by Maddie Schipper on 3/16/21.
//

import Foundation

extension Sequence {
    @inlinable
    public func unique() -> Array<Iterator.Element> where Iterator.Element : Identifiable {
        return unique(by: \.id)
    }
    
    @inlinable
    public func unique<V : Hashable>(by: (Iterator.Element) -> V) -> Array<Iterator.Element> {
        var seen = Set<V>()
        
        return self.filter { seen.insert(by($0)).inserted }
    }
}
