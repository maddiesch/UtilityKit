//
//  NSSortDescriptor.swift
//  
//
//  Created by Maddie Schipper on 3/11/21.
//

import Foundation

extension NSSortDescriptor {
    public convenience init(caseInsensitiveCompareForKey key: String?, ascending: Bool) {
        self.init(key: key, ascending: ascending, selector: #selector(NSString.caseInsensitiveCompare(_:)))
    }
    
    public convenience init(key: CustomStringConvertible?, ascending: Bool) {
        self.init(key: key?.description, ascending: ascending)
    }
}
