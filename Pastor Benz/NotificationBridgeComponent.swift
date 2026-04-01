import Foundation
import HotwireNative
import UserNotifications

final class NotificationBridgeComponent: BridgeComponent {
    override class var name: String { "notification" }
    
    override func onReceive(message: Message) {
        let event = message.event
        
        switch event {
        case "request-permission":
            requestNotificationPermission(message: message)
        case "check-permission":
            checkNotificationPermission(message: message)
        default:
            print("⚠️ NotificationBridgeComponent: Unknown event '\(event)'")
        }
    }
    
    private func requestNotificationPermission(message: Message) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            Task { @MainActor in
                if let error = error {
                    print("⚠️ NotificationBridgeComponent: Error requesting permission - \(error)")
                    try? await self.reply(to: "request-permission", with: ["granted": false])
                } else {
                    try? await self.reply(to: "request-permission", with: ["granted": granted])
                }
            }
        }
    }
    
    private func checkNotificationPermission(message: Message) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                let granted = settings.authorizationStatus == .authorized
                try? await self.reply(to: "check-permission", with: ["granted": granted])
            }
        }
    }
}
