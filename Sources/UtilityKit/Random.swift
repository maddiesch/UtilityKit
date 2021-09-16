//
//  Random.swift
//  UtilityKit
//
//  Created by Maddie Schipper on 9/16/21.
//

import Foundation
import Security

public struct Random {
    public enum Error : Swift.Error {
        case underlyingError(Int32)
    }
    
    public static func generateBytes(count: Int) throws -> Data {
        precondition(count % 2 == 0)
        
        var bytes = [UInt8](repeating: 0, count: count)
        
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        
        guard status == errSecSuccess else {
            throw Error.underlyingError(status)
        }
        
        return Data(bytes)
    }
}
