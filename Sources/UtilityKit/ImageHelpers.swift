//
//  ImageHelpers.swift
//  
//
//  Created by Maddie Schipper on 3/14/21.
//

import Foundation
import CoreGraphics

public struct ImageExporter {
    public enum Error : Swift.Error {
        case dataAllocatorFailed
        case destinationAllocatorFailed
        case destinationFinalizationFailed
    }
    
    public enum FileFormat {
        case png
        
        fileprivate var universalTypeIdentifier: CFString {
            switch self {
            case .png:
                return kUTTypePNG
            }
        }
    }
    
    public static func export(image: CGImage, toFormat format: FileFormat) throws -> Data {
        guard let data = CFDataCreateMutable(kCFAllocatorDefault, 0) else {
            throw Error.dataAllocatorFailed
        }
        guard let destination = CGImageDestinationCreateWithData(data, format.universalTypeIdentifier, 1, nil) else {
            throw Error.destinationAllocatorFailed
        }
        
        CGImageDestinationAddImage(destination, image, nil)
        
        guard CGImageDestinationFinalize(destination) else {
            throw Error.destinationFinalizationFailed
        }
        
        return data as Data
    }
}
