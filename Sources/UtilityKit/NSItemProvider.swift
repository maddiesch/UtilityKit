//
//  NSItemProvider.swift
//  
//
//  Created by Maddie Schipper on 3/14/21.
//

import Foundation
import Combine
import UniformTypeIdentifiers

public struct ItemProviderError : Error {
    public let message: String
}

extension ItemProviderError : CustomNSError {
    public var errorUserInfo: [String : Any] {
        return [
            NSLocalizedDescriptionKey: self.message
        ]
    }
}

extension NSItemProvider {
    public func loadFileURL(forTypeIdentifier typeIdentifier: UTType) -> Future<URL, Error> {
        return Future { promise in
            self.loadDataRepresentation(forTypeIdentifier: typeIdentifier.identifier) { (unsafeDataURL, unsafeError) in
                guard unsafeError == nil else {
                    promise(.failure(unsafeError!))
                    return
                }
                guard let data = unsafeDataURL else {
                    let message = NSLocalizedString("UtilityKit.ItemProviderError.NilData", bundle: Bundle.module, comment: "Message for error when ItemProvider returns nil Data")
                    let error = ItemProviderError(message: message)
                    promise(.failure(error))
                    return
                }
                
                switch typeIdentifier.identifier {
                case String(kUTTypeFileURL):
                    guard let fileURL = URL(dataRepresentation: data, relativeTo: nil) else {
                        let message = NSLocalizedString("UtilityKit.ItemProviderError.URLConversionError", bundle: Bundle.module, comment: "Message for error when data can't be converted to file")
                        let error = ItemProviderError(message: message)
                        promise(.failure(error))
                        return
                    }
                    
                    promise(.success(fileURL))
                default:
                    let message = NSLocalizedString("UtilityKit.ItemProviderError.UnsupportedType \(typeIdentifier.identifier)", bundle: Bundle.module, comment: "Message for error when data loaded isn't a file url")
                    let error = ItemProviderError(message: message)
                    promise(.failure(error))
                }
            }
        }
    }
}
