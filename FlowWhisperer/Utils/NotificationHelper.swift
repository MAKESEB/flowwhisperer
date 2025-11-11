import Foundation
import UserNotifications

class NotificationHelper {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    static func showNotification(title: String, body: String, sound: UNNotificationSound?) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        if let sound = sound {
            content.sound = sound
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Show immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }
    
    static func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}