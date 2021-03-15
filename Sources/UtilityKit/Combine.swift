//
//  Combine.swift
//  
//
//  Created by Maddie Schipper on 3/14/21.
//

import Foundation
import Combine

extension Subscribers.Completion {
    public var isFinished: Bool {
        switch self {
        case .finished:
            return true
        case .failure:
            return false
        }
    }
}
