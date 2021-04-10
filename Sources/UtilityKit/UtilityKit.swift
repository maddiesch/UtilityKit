//
//  UtilityKit.swift
//
//
//  Created by Maddie Schipper on 3/6/21.
//

import Foundation

/// ApplicationIdentifier
///
/// Returns the either a bundle identifier for an application or the UtilityKit identifier as a fallback
public let ApplicationIdentifier: String = Identifier(for: .main)

public let ApplicationVersion: String = ShortVersionString(for: .main)

fileprivate func Identifier(for bundle: Bundle) -> String {
    if let bundleIdentifier = bundle.bundleIdentifier {
        return bundleIdentifier
    }
    return "dev.schipper.UtilityKit"
}

public func ShortVersionString(for bundle: Bundle) -> String {
    if let bundleShortVersion = bundle.localizedInfoDictionary?["CFBundleShortVersionString"] as? String {
        return bundleShortVersion
    }
    return "0.0"
}

public struct StringEncodingError : Error {
    public let format: String.Encoding
}

extension String {
    public func data(in format: String.Encoding, allowLossyConversion lossy: Bool = false) throws -> Data {
        guard let data = self.data(using: format, allowLossyConversion: lossy) else {
            throw StringEncodingError(format: format)
        }
        return data
    }
}

extension Data {
    public init?(base64URLEncoded input: String) {
        var base64 = input
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 = base64.appending("=")
        }
        self.init(base64Encoded: base64)
    }

    public func base64URLEncodedString() -> String {
        var result = self.base64EncodedString()
        result = result.replacingOccurrences(of: "+", with: "-")
        result = result.replacingOccurrences(of: "/", with: "_")
        result = result.replacingOccurrences(of: "=", with: "")
        return result
    }
}

import os.log

public func CreateLogger(category: String) -> os.Logger {
    return Logger(subsystem: ApplicationIdentifier, category: category)
}
