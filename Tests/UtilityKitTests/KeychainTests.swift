//
//  KeychainTests.swift
//  
//
//  Created by Maddie Schipper on 6/14/21.
//

import XCTest
@testable import UtilityKit

class KeychainTests : XCTestCase {
    func testGenericPasswordKeychainItem() throws {
        let itemClass = Keychain.ItemClass.genericPassword(service: "testing", account: "test-1")
        let keychainItem = Keychain.Item(itemClass, identifier: "test-account")
        
        try keychainItem.write("Testing Writing & Reading")
        
        XCTAssertTrue(try keychainItem.exists)
        
        let data = try keychainItem.dataValue
        
        let string = String(data: data, encoding: .utf8)!
        
        XCTAssertEqual("Testing Writing & Reading", string)
        
        try keychainItem.destroy()
    }
}
