//
//  Networking.swift
//  
//
//  Created by Maddie Schipper on 3/7/21.
//

import Foundation
import Combine

extension Publisher where Output == URLSession.DataTaskPublisher.Output {
    internal func require2xxResponse() -> AnyPublisher<URLSession.DataTaskPublisher.Output, Error> {
        return self.require(httpStatusWithinRange: (200..<300))
    }
    
    internal func require(httpStatusWithinRange range: Range<Int>) -> AnyPublisher<URLSession.DataTaskPublisher.Output, Error> {
        return self.tryMap { (data, response) -> URLSession.DataTaskPublisher.Output in
            guard let httpResponse = response as? HTTPURLResponse, range.contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            return URLSession.DataTaskPublisher.Output(data, response)
        }.eraseToAnyPublisher()
    }
}
