//
//  KeychainAccess.swift
//  
//
//  Created by Maddie Schipper on 3/22/21.
//

import Foundation
import Security
import os.log

fileprivate let KeychainLog = Logger(subsystem: ApplicationIdentifier, category: "Keychain")

@available(*, deprecated, message: "KeychainItem has been deprecated in favor of Keychain.Item.")
public struct KeychainItem {
    public enum Error : Swift.Error {
        case itemNotFound
        case unsupportedValueType
        case securityError(OSStatus)
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
    
    public enum ItemClass : String {
        case genericPassword
        
        fileprivate var secClass: String {
            switch self {
            case .genericPassword:
                return kSecClassGenericPassword as String
            }
        }
    }
    
    public let service: String
    public let accessGroup: String?
    
    public var accessibility: Accessibility = .afterFirstUnlock
    public var itemClass: ItemClass = .genericPassword
    
    public init(accessGroup: String? = nil) {
        self.init(service: ApplicationIdentifier, accessGroup: accessGroup)
    }
    
    public init(service: String, accessGroup: String?) {
        self.service = service
        self.accessGroup = accessGroup
    }
    
    internal var query: Dictionary<String, Any> {
        var query = Dictionary<String, Any>()
        
        query[kSecClass as String] = self.itemClass.secClass
        
        if let accessGroup = self.accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        query[kSecAttrAccessible as String] = self.accessibility.secValue
        
        switch self.itemClass {
        case .genericPassword:
            query[kSecAttrService as String] = self.service
        }
        
        return query
    }
}

@available(*, deprecated)
extension KeychainItem {
    public func exists(forKey key: String) -> Bool {
        do {
            _ = try self.get(valueForKey: key)
            
            return true
        } catch {
            return false
        }
    }
    
    public func get(optionalValueForKey key: String) throws -> Data? {
        do {
            return try self.get(valueForKey: key)
        } catch let error as Error {
            switch error {
            case .itemNotFound:
                return nil
            default:
                throw error
            }
        } catch {
            throw error
        }
    }
    
    public func get(valueForKey key: String) throws -> Data {
        var query = self.query
        
        query[kSecAttrAccount as String] = key
        query[kSecReturnData as String] = kCFBooleanTrue
        
        var output: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &output)
        
        KeychainLog.trace("Get item for key - \(self.service).\(key)")
        
        switch status {
        case errSecSuccess:
            guard let data = output as? Data else {
                throw Error.unsupportedValueType
            }
            return data
        case errSecItemNotFound:
            throw Error.itemNotFound
        default:
            throw Error.securityError(status)
        }
    }
    
    public func set(_ value: Data, forKey key: String) throws {
        var query = self.query
        
        query[kSecAttrAccount as String] = key
        query[kSecReturnData as String] = kCFBooleanTrue
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        
        KeychainLog.trace("Set item for key - \(self.service).\(key)")
        
        switch status {
        case errSecSuccess, errSecInteractionNotAllowed:
            var attributes = Dictionary<String, Any>()
            attributes[kSecAttrAccount as String] = key
            attributes[kSecValueData as String] = value
            attributes[kSecAttrAccessible as String] = self.accessibility.secValue
            attributes[kSecAttrModificationDate as String] = Date()
            
            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            guard status == errSecSuccess else {
                throw Error.securityError(status)
            }
        case errSecItemNotFound:
            query[kSecValueData as String] = value
            
            let status = SecItemAdd(query as CFDictionary, nil)
            guard status == errSecSuccess else {
                throw Error.securityError(status)
            }
        default:
            throw Error.securityError(status)
        }
    }
    
    public func delete(valueForKey key: String) throws {
        var query = self.query
        
        query[kSecAttrAccount as String] = key
        
        KeychainLog.trace("Delete item for key - \(self.service).\(key)")
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess, errSecItemNotFound:
            break // success
        default:
            throw Error.securityError(status)
        }
    }
}

@available(*, deprecated)
extension KeychainItem {
    public func set<V : Encodable>(_ value: V, forKey key: String, usingEncoder encoder: JSONEncoder = JSONEncoder()) throws {
        let data = try encoder.encode(value)
        
        try self.set(data, forKey: key)
    }
    
    public func get<V : Decodable>(_ type: V.Type, forKey key: String, usingDecoder decoder: JSONDecoder = JSONDecoder()) throws -> V {
        let data = try self.get(valueForKey: key)
        
        return try decoder.decode(type, from: data)
    }
}

@available(*, deprecated)
extension KeychainItem.Error : CustomNSError {
    public var errorCode: Int {
        switch self {
        case .itemNotFound:
            return 404
        case .unsupportedValueType:
            return 500
        case .securityError(_):
            return 220
        }
    }
    
    private var _localizedDescriptionValue: String {
        switch self {
        case .itemNotFound:
            return NSLocalizedString("UtilityKit.KeychainError.ItemNotFound", bundle: .module, comment: "")
        case .unsupportedValueType:
            return NSLocalizedString("UtilityKit.KeychainError.UnsupportedValueType", bundle: .module, comment: "")
        case .securityError(let value):
            return NSString(format: NSLocalizedString("UtilityKit.KeychainError.Security %i", bundle: .module, comment: "") as NSString, value) as String
        }
    }
    
    public var errorUserInfo: [String : Any] {
        return [NSLocalizedDescriptionKey: self._localizedDescriptionValue]
    }
}
