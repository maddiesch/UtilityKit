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
public let ApplicationIdentifier: String = {
    if let bundleIdentifier = Bundle.main.bundleIdentifier {
        return bundleIdentifier
    }
    return "dev.schipper.UtilityKit"
}()
