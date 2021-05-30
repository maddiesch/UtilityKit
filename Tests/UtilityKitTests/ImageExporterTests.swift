//
//  ImageExporterTests.swift
//  
//
//  Created by Maddie Schipper on 5/30/21.
//

import XCTest
@testable import UtilityKit

final class ImageExporterTests : XCTestCase {
    var cgImage: CGImage {
        let image = NSImage(contentsOf: Bundle.module.url(forResource: "apple", withExtension: "heic")!)!
        
        var rect = CGRect(origin: .zero, size: image.size)
        return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
    }
    
    func testConvertingIntoPNG() throws {
        _ = try ImageExporter.export(image: cgImage, toFormat: .png)
    }
    
    func testConvertingIntoJPEG() throws {
        _ = try ImageExporter.export(image: cgImage, toFormat: .jpeg)
    }
    
    func testConvertingIntoHEIC() throws {
        _ = try ImageExporter.export(image: cgImage, toFormat: .heic)
    }
}
