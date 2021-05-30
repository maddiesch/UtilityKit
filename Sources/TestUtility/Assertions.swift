//
//  Assertions.swift
//  
//
//  Created by Maddie Schipper on 3/22/21.
//

import XCTest
import Combine

public func AssertFinished<Failure>(_ completion: Subscribers.Completion<Failure>, _ message: String? = nil) {
    switch completion {
    case .failure(let error):
        XCTFail(message ?? "Completion Failed with Error \(error.localizedDescription)")
    default:
        break
    }
}


@available(*, deprecated, renamed: "AssertFinished")
public func TestAssertFinished<Failure>(_ completion: Subscribers.Completion<Failure>, _ message: String? = nil) {
    AssertFinished(completion, message)
}
