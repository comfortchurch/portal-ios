import Foundation
import HotwireNative
import UserNotifications
import FirebaseMessaging

final class NotificationBridgeComponent: BridgeComponent {
    override class var name: String { "notification" }

    override func onReceive(message: Message) {
        switch message.event {
        case "connect":
            handleConnect(message: message)
        case "requestPermission":
            requestNotificationPermission(message: message)
        case "redirectUser":
            // No-op — web handles navigation via Turbo.visit
            break
        default:
            print("⚠️ NotificationBridgeComponent: Unknown event '\(message.event)'")
        }
    }

    private func handleConnect(message: Message) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let hasPermission = settings.authorizationStatus == .authorized

            Messaging.messaging().token { token, error in
                Task { @MainActor in
                    if let error = error {
                        print("⚠️ NotificationBridgeComponent: FCM token error - \(error)")
                    }
                    try? await self.reply(to: "connect", with: [
                        "token": token ?? "",
                        "hasPermission": hasPermission
                    ])
                }
            }
        }
    }

    private func requestNotificationPermission(message: Message) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            Task { @MainActor in
                if let error = error {
                    print("⚠️ NotificationBridgeComponent: Error requesting permission - \(error)")
                }
                try? await self.reply(to: "requestPermission", with: ["granted": granted])
            }
        }
    }
}
