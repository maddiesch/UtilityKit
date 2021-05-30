//
//  ImageExporter.swift
//  
//
//  Created by Maddie Schipper on 3/14/21.
//

import Foundation
import CoreGraphics
import CoreServices
import ImageIO
import UniformTypeIdentifiers

public struct ImageExporter {
    public enum Error : Swift.Error {
        case dataAllocatorFailed
        case destinationAllocatorFailed
        case destinationFinalizationFailed
    }
    
    public enum FileFormat {
        case png
        case jpeg
        case heic
        
        fileprivate var universalTypeIdentifier: UTType {
            switch self {
            case .png:
                return .png
            case .jpeg:
                return .jpeg
            case .heic:
                return .heic
            }
        }
    }
    
    public static func export(image: CGImage, toFormat format: FileFormat) throws -> Data {
        guard let data = CFDataCreateMutable(kCFAllocatorDefault, 0) else {
            throw Error.dataAllocatorFailed
        }
        guard let destination = CGImageDestinationCreateWithData(data, format.universalTypeIdentifier.identifier as CFString, 1, nil) else {
            throw Error.destinationAllocatorFailed
        }
        
        CGImageDestinationAddImage(destination, image, nil)
        
        guard CGImageDestinationFinalize(destination) else {
            throw Error.destinationFinalizationFailed
        }
        
        return data as Data
    }
}
