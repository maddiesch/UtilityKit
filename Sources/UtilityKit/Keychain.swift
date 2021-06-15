//
//  Keychain.swift
//  
//
//  Created by Maddie Schipper on 6/14/21.
//

import Foundation
import Security

public enum Keychain {
    public enum Error : Swift.Error {
        case secError(OSStatus)
        case itemNotFound
        case invalidStringEncoding
        case unexpectedResultType
        case missingResultValue(PartialKeyPath<Result>)
    }
    
    /// Provides a Swift wrapper around Security access keys
    public enum ItemClass {
        case genericPassword(service: String, account: String)
        case internetPassword(server: String, account: String)
        case certificate
        case key
        case identity
        
        fileprivate var secValue: String {
            switch self {
            case .genericPassword:
                return kSecClassGenericPassword as String
            case .internetPassword:
                return kSecClassInternetPassword as String
            case .certificate:
                return kSecClassCertificate as String
            case .key:
                return kSecClassKey as String
            case .identity:
                return kSecClassIdentity as String
            }
        }
    }
    
    public enum Accessibility {
        case whenUnlocked
        case afterFirstUnlock
        case whenUnlockedThisDeviceOnly
        case afterUnlockThisDeviceOnly
        
        fileprivate var secValue: String {
            switch self {
            case .whenUnlocked:
                return kSecAttrAccessibleWhenUnlocked as String
            case .afterFirstUnlock:
                return kSecAttrAccessibleAfterFirstUnlock as String
            case .whenUnlockedThisDeviceOnly:
                return kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
            case .afterUnlockThisDeviceOnly:
                return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
            }
        }
    }
    
    public struct Item {
        public let itemClass: ItemClass
        public let identifer: Data
        public let accessGroup: String?
        public var accessibility: Accessibility = .afterFirstUnlock
        public var isPermanant: Bool = true
        public var userVisibleName: String? = nil
        public var userDescription: String? = nil
        public var isSynchronizable: Bool = false
        
        public init(_ itemClass: ItemClass, identifier: String, accessGroup: String? = nil) {
            guard let dataIdentifier = identifier.data(using: .utf8, allowLossyConversion: false) else {
                fatalError("The provided identifier is not valid UTF-8 data")
            }
            self.init(itemClass, identifier: dataIdentifier, accessGroup: accessGroup)
        }
        
        public init(_ itemClass: ItemClass, identifier: Data, accessGroup: String? = nil) {
            self.itemClass = itemClass
            self.identifer = identifier
            self.accessGroup = accessGroup
        }
        
        public var exists: Bool {
            get throws {
                let status = SecItemCopyMatching(itemQuery as CFDictionary, nil)
                
                switch status {
                case errSecSuccess:
                    return true
                case errSecNoSuchAttr, errSecItemNotFound:
                    return false
                default:
                    throw Error.secError(status)
                }
            }
        }
        
        public var dataValue: Data {
            get throws {
                return try fetchResult().data
            }
        }
        
        public func fetchResult() throws -> Result {
            let attr = try fetchCurrentAttributes()
            
            return try Result(attr)
        }
        
        private func fetchCurrentAttributes() throws -> [CFString: Any] {
            var baseQuery = itemQuery
            
            baseQuery[kSecReturnAttributes] = true
            baseQuery[kSecReturnData] = true
            
            var result: AnyObject?
            let queryStatus = SecItemCopyMatching(baseQuery as CFDictionary, &result)
            guard queryStatus == errSecSuccess else {
                switch queryStatus {
                case errSecNoSuchAttr:
                    throw Error.itemNotFound
                default:
                    throw Error.secError(queryStatus)
                }
            }
            
            guard let queryResultAttributes = result as? [CFString: Any] else {
                throw Error.unexpectedResultType
            }
            
            return queryResultAttributes
        }
        
        public func write<T : Encodable>(_ codable: T, encoder: JSONEncoder = JSONEncoder()) throws {
            let data = try encoder.encode(codable)
            try write(data)
        }
        
        public func write(_ string: String) throws {
            guard let data = string.data(using: .utf8, allowLossyConversion: false) else {
                throw Error.invalidStringEncoding
            }
            
            try write(data)
        }
        
        public func write(_ data: Data) throws {
            if try exists {
                try update(data)
            } else {
                try create(data)
            }
        }
        
        private func create(_ data: Data) throws {
            var baseQuery = itemQuery
            
            baseQuery[kSecValueData] = data
            
            let status = SecItemAdd(baseQuery as CFDictionary, nil)
            
            guard status == errSecSuccess else {
                throw Error.secError(status)
            }
        }
        
        private func update(_ data: Data) throws {
            var baseQuery = itemQuery
            
            baseQuery[kSecValueData] = data
            
            let status = SecItemUpdate(itemQuery as CFDictionary, baseQuery as CFDictionary)
            
            guard status == errSecSuccess else {
                throw Error.secError(status)
            }
        }
        
        public func destroy() throws {
            guard try exists else {
                return
            }
            
            let status = SecItemDelete(itemQuery as CFDictionary)
            
            guard status == errSecSuccess else {
                throw Error.secError(status)
            }
        }
        
        private var itemQuery: [CFString: Any] {
            var query: [CFString: Any] = [
                kSecClass: itemClass.secValue,
                kSecAttrApplicationTag: identifer,
                kSecAttrAccessible: accessibility.secValue,
                kSecAttrIsPermanent: isPermanant
            ]
            
            if isSynchronizable {
                query[kSecAttrSynchronizable] = isSynchronizable
            }
            
            if let accessGroup = accessGroup {
                query[kSecAttrAccessGroup] = accessGroup
            }
            
            if let userVisibleName = userVisibleName {
                query[kSecAttrLabel] = userVisibleName
            }
            
            if let userDescription = userDescription {
                query[kSecAttrDescription] = userDescription
            }
            
            switch itemClass {
            case .genericPassword(service: let service, account: let account):
                query[kSecAttrService] = service
                query[kSecAttrAccount] = account
            case .internetPassword(server: let server, account: let account):
                query[kSecAttrServer] = server
                query[kSecAttrAccount] = account
            default:
                break
            }
            
            return query
        }
    }
    
    public struct Result {
        let data: Data
        let updatedAt: Date
        let createdAt: Date
        let description: String?
        let name: String?
        
        init(_ attr: [CFString: Any]) throws {
            guard let data = attr[kSecValueData] as? Data else {
                throw Keychain.Error.missingResultValue(\Result.data)
            }
            guard let updatedAt = attr[kSecAttrModificationDate] as? Date else {
                throw Keychain.Error.missingResultValue(\Result.updatedAt)
            }
            guard let createdAt = attr[kSecAttrCreationDate] as? Date else {
                throw Keychain.Error.missingResultValue(\Result.createdAt)
            }
            
            
            self.data = data
            self.updatedAt = updatedAt
            self.createdAt = createdAt
            self.description = attr[kSecAttrDescription] as? String
            self.name = attr[kSecAttrLabel] as? String
        }
    }
}
