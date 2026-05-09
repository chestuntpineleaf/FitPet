import UserNotifications
import Foundation

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    func scheduleMorningAdvice(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "MORNING_ADVICE"
        
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 30
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_advice", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func schedulePetMissYou() {
        let content = UNMutableNotificationContent()
        content.title = "🐱 \u{200B}宠物想你了"
        content.body = "小元已经等了你好久啦，来看看它吧！"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 19
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "pet_miss_you", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleRestReminder() {
        let content = UNMutableNotificationContent()
        content.title = "💤 该休息了"
        content.body = "今天运动量已经够了，好好休息让身体恢复吧！"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 22
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "rest_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleInactivityReminder(afterHours: Int = 4) {
        let content = UNMutableNotificationContent()
        content.title = "🏃 动起来吧！"
        content.body = "已经坐了很久了，站起来活动一下吧！小元在等你一起运动~"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(afterHours * 3600), repeats: false)
        let request = UNNotificationRequest(identifier: "inactivity_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
