//
//  Networking.swift
//  
//
//  Created by Maddie Schipper on 3/7/21.
//

import Foundation
import Combine

public struct HTTPResponseError : Error {
    public let statusCode: Int
    public let responseBody: Data?
    public let responseHeaders: Dictionary<AnyHashable, Any>
}

extension HTTPResponseError : CustomNSError {
    public var errorCode: Int {
        return self.statusCode
    }
}

extension Publisher where Output == URLSession.DataTaskPublisher.Output {
    public func require2xxResponse() -> AnyPublisher<URLSession.DataTaskPublisher.Output, Error> {
        return self.require(httpStatusWithinRange: (200..<300))
    }
    
    public func require(httpStatusWithinRange range: Range<Int>) -> AnyPublisher<URLSession.DataTaskPublisher.Output, Error> {
        return self.tryMap { (data, response) -> URLSession.DataTaskPublisher.Output in
            try response.require(httpStatusCodeWithinRange: range)
            
            return URLSession.DataTaskPublisher.Output(data, response)
        }.eraseToAnyPublisher()
    }
}

extension URLResponse {
    @discardableResult
    public func require2xxResponse() throws -> Int {
        return try self.require(httpStatusCodeWithinRange: (200..<300))
    }
    
    @discardableResult
    public func require(httpStatusCodeWithinRange range: Range<Int>) throws -> Int {
        guard let httpResponse = self as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard range.contains(httpResponse.statusCode) else {
            throw HTTPResponseError(
                statusCode: httpResponse.statusCode,
                responseBody: nil,
                responseHeaders: httpResponse.allHeaderFields
            )
        }
        
        return httpResponse.statusCode
    }
}

extension URLRequest {
    public mutating func basicAuthorization(_ username: String, _ password: String) throws {
        let data = try "\(username):\(password)".data(in: .utf8)
        let encoded = data.base64EncodedString()
        
        self.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
    }
    
    public mutating func set(formURLEncodedBody items: [URLQueryItem]) throws {
        self.httpBody = try items.encoded().data(in: .utf8)
        self.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
    }
    
    public mutating func authorize(withBearerToken token: String) {
        self.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}

extension Sequence where Element == URLQueryItem {
    public func encoded() -> String {
        var results = Array<String>()
        
        for queryItem in self {
            guard let value = queryItem.value else {
                continue
            }
            guard let encoded = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                continue
            }
            
            results.append("\(queryItem.name)=\(encoded)")
        }
        
        return results.joined(separator: "&")
    }
}
