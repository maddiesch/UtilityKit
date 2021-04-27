import XCTest
import TestUtility
@testable import UtilityKit

final class UtilityKitTests: XCTestCase {
    func testHostReachability() throws {
        let reachability = try Reachability(source: .host("www.google.com"))
        
        let expectation = self.expectation(description: "connects and checks reachability")
        
        try reachability.start()
        
        let canceler = reachability.publisher.debounce(for: 0.1, scheduler: DispatchQueue.main).sink { (value) in
            XCTAssertEqual(value, .reachableWiFi)
            
            expectation.fulfill()
        }
        
        self.wait(for: [expectation], timeout: 1)
        
        canceler.cancel()
    }
    
    func testIPv4ZeroReachability() throws {
        let reachability = try Reachability(source: .ip(.v4_zero))
        
        let expectation = self.expectation(description: "connects and checks reachability")
        
        try reachability.start()
        
        let canceler = reachability.publisher.debounce(for: 0.1, scheduler: DispatchQueue.main).sink { (value) in
            XCTAssertEqual(value, .reachableWiFi)
            
            expectation.fulfill()
        }
        
        self.wait(for: [expectation], timeout: 1)
        
        canceler.cancel()
    }
    
    func testIPv6ZeroReachability() throws {
        let reachability = try Reachability(source: .ip(.v6_zero))
        
        let expectation = self.expectation(description: "connects and checks reachability")
        
        try reachability.start()
        
        let canceler = reachability.publisher.debounce(for: 0.1, scheduler: DispatchQueue.main).sink { (value) in
            XCTAssertEqual(value, .reachableWiFi)
            
            expectation.fulfill()
        }
        
        self.wait(for: [expectation], timeout: 1)
        
        canceler.cancel()
    }
    
    func testMutexSetupAndDestroy() {
        let mutex = Mutex()
        
        let expectation = self.expectation(description: "threading lock")
        
        DispatchQueue.global(qos: .background).async {
            mutex.synchronized {
                expectation.fulfill()
            }
        }
        
        self.wait(for: [expectation], timeout: 0.1)
    }
    
    func testAddressResolution() {
        let expection = self.expectation(description: "resolved")
        
        var results = Array<ResolvedAddress>()
        
        let canceler = ResolveAddresses(forHost: "maddiesch.com").sink { (completion) in
            TestAssertFinished(completion)
            
            expection.fulfill()
        } receiveValue: { (r) in
            results = r
        }
        
        self.wait(for: [expection], timeout: 1)
        
        canceler.cancel()
        
        XCTAssertGreaterThan(results.count, 0)
    }
    
    func testKeychainAccessWriting() throws {
        let keychain = KeychainItem()
        
        try keychain.set(Data(), forKey: "testing")
        
        _ = try keychain.get(valueForKey: "testing")
        
        try keychain.delete(valueForKey: "testing")
        try keychain.delete(valueForKey: "testing")
    }
    
    func testWorkQueue() throws {
        let queue = JobQueue(concurrentJobs: 2)
        
        queue.submit {
            sleep(1)
            print("Work Item (1): \(Date().timeIntervalSince1970)")
        }
        
        queue.submit {
            sleep(2)
            print("Work Item (2): \(Date().timeIntervalSince1970)")
        }
        
        queue.submit {
            sleep(2)
            print("Work Item (3): \(Date().timeIntervalSince1970)")
        }
        
        queue.wait()
        
        try queue.submitAndWait(JobQueue.BlockItem {
            print("Work Item (4): \(Date().timeIntervalSince1970)")
        })
    }
}
