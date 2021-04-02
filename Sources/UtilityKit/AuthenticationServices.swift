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

fileprivate class _AuthenticationSessionViewModel : NSObject, ASWebAuthenticationPresentationContextProviding {
    static let `default`: _AuthenticationSessionViewModel = .init()
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}
