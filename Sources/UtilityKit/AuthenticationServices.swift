//
//  AuthenticationServices.swift
//  
//
//  Created by Maddie Schipper on 3/24/21.
//

import Foundation
import Combine
import AuthenticationServices

extension ASWebAuthenticationSession {
    public static func beginAuthentication(for url: URL, callbackURLScheme: String) -> Future<URL, Error> {
        return Future { finished in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme) { (unsafeURL, unsafeError) in
                if let error = unsafeError {
                    finished(.failure(error))
                } else if let url = unsafeURL {
                    finished(.success(url))
                } else {
                    finished(.failure(URLError(.badURL)))
                }
            }
            
            session.presentationContextProvider = _AuthenticationSessionViewModel.default
            session.start()
        }
    }
}

extension ASWebAuthenticationSession {
    @available(macOS 12.0.0, iOS 15.0.0, *)
    public static func beginAuthentication(for url: URL, callbackURLScheme: String) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme) { unsafeURL, unsafeError in
                    if let error = unsafeError {
                        continuation.resume(throwing: error)
                    } else if let url = unsafeURL {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(throwing: URLError(.badURL))
                    }
                }
                
                session.presentationContextProvider = _AuthenticationSessionViewModel.default
                session.start()
            }
        }
    }
}

fileprivate class _AuthenticationSessionViewModel : NSObject, ASWebAuthenticationPresentationContextProviding {
    static let `default`: _AuthenticationSessionViewModel = .init()
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}
