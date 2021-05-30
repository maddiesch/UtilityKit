//
//  ResourcePoolTests.swift
//  
//
//  Created by Maddie Schipper on 5/30/21.
//

import XCTest
@testable import UtilityKit

final class ResourcePoolTests : XCTestCase {
    func testResourcePool() throws {
        let pool = ResourcePool(size: 2) { () -> UUID in
            return UUID()
        }
        
        let expectation = self.expectation(description: "Finished")
        expectation.expectedFulfillmentCount = 100
        
        let queue = DispatchQueue(label: "test-queue", attributes: .concurrent)
        
        for _ in 0..<100 {
            queue.async {
                defer { expectation.fulfill() }
                
                print(pool.with { usleep(arc4random() % 1000); return $0 })
            }
        }
        
        self.wait(for: [expectation], timeout: 2.0)
    }
}
