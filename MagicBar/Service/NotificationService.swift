//
//  NotificationService.swift
//  MagicBar
//
//  Created by Atiyeh, Brian (B.) on 5/11/20.
//  Copyright © 2020 Brian Atiyeh. All rights reserved.
//

import Foundation
import UserNotifications

public protocol NotificationServicable {
    var sendable: Bool { get }
    func send()
}

class NotificationService {
    private typealias Notification = NSUserNotification
    public var requested = false
    let notificationCenter: UNUserNotificationCenter
    
    init(notificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current()) {
        self.notificationCenter = notificationCenter
    }
    
    func send(title: String, body: String, caption: String? = nil) {
        notificationCenter.getNotificationSettings { settings in
            guard (settings.authorizationStatus == .authorized) ||
                  (settings.authorizationStatus == .provisional) else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            
            if let caption = caption {
                content.subtitle = caption
            }
            
            let uuidString = UUID().uuidString
            let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: nil)
            self.notificationCenter.add(request)
        }
    }
    
    func requestNotificationAccess() {
        if !requested {
            notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let _ = error { self.requested = false }
                
                if granted {
                    self.requested = true
                }
            }
        }
    }
}
