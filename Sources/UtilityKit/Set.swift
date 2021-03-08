//
//  Set.swift
//  
//
//  Created by Maddie Schipper on 3/7/21.
//

import Combine

extension Set where Element == AnyCancellable {
    public mutating func cancelAll() {
        for canceler in self {
            canceler.cancel()
        }
        
        self.removeAll()
    }
}
