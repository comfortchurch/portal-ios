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
                    let payload: [String: Any] = [
                        "token": token ?? "",
                        "hasPermission": hasPermission
                    ]
                    if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        do {
                            try await self.reply(to: "connect", with: jsonString)
                        } catch {
                            print("⚠️ NotificationBridgeComponent: reply error - \(error)")
                        }
                    }
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
                let payload: [String: Any] = ["granted": granted]
                if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    do {
                        try await self.reply(to: "requestPermission", with: jsonString)
                    } catch {
                        print("⚠️ NotificationBridgeComponent: reply error - \(error)")
                    }
                }
            }
        }
    }
}
