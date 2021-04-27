//
//  NotificationController.swift
//  
//
//  Created by Maddie Schipper on 4/26/21.
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

#if os(macOS)
public typealias UTKApplication = NSApplication
#else
public typealias UTKApplication = UIApplication
#endif

public final class NotificationController {
    public static let shared = NotificationController()
    
    private static let logger = CreateLogger(category: "NotificationController")
    
    private var currentUserNotificationCenter: UNUserNotificationCenter {
        return UNUserNotificationCenter.current()
    }
    
    public func userNotificationSettings() -> Future<UNNotificationSettings, Never> {
        NotificationController.logger.debug("Fetching User Notification Settings")
        
        return Future { promise in
            self.currentUserNotificationCenter.getNotificationSettings { settings in
                promise(.success(settings))
            }
        }
    }
    
    public func requestAuthorization(options: UNAuthorizationOptions = []) -> Future<Bool, Error> {
        return Future { promise in
            self.currentUserNotificationCenter.requestAuthorization(options: options) { (granted, unsafeError) in
                NotificationController.logger.debug("Notification Authorization Requested -- \(granted, privacy: .public)")
                
                if let error = unsafeError {
                    NotificationController.logger.error("Failed to fetch notification authorization with error -- \(error.localizedDescription)")
                    
                    promise(.failure(error))
                } else {
                    promise(.success(granted))
                }
            }
        }
    }
    
    public func registerForRemoteNotifications(_ application: UTKApplication = .shared) {
        NotificationController.logger.debug("Registering for remote notifications")
        
        application.registerForRemoteNotifications()
    }
}
