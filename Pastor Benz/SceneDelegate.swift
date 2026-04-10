// SceneDelegate.swift
import UIKit
import HotwireNative

let baseURL = URL(string: "https://portal-v2.comfortchurch.in")!
// For local dev: URL(string: "http://localhost:8000")!

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private lazy var navigator = Navigator(
        configuration: Navigator.Configuration(
            name: "ComfortChurch",
            startLocation: baseURL
        )
    )

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Configure Hotwire
        Hotwire.config.debugLoggingEnabled = true
        Hotwire.config.applicationUserAgentPrefix = "ComfortChurchApp-iOS; App Version \(appVersion);"

        // Use custom navigation controller with hidden navigation bar
        Hotwire.config.defaultNavigationController = {
            HotwireNavigationController()
        }

        // Use custom view controller
        Hotwire.config.defaultViewController = { url in
            CustomWebViewController(url: url)
        }

        // Register bridge components
        Hotwire.registerBridgeComponents([
            ShareBridgeComponent.self,
            NotificationBridgeComponent.self
        ])

        // Load path configuration
        Hotwire.loadPathConfiguration(from: [
            .server(baseURL.appendingPathComponent("/configurations.json")) // optional remote
        ])

        // Setup window and root navigation
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = navigator.rootViewController
        window?.makeKeyAndVisible()

        navigator.start()

        // Listen for notification taps to navigate
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotificationTap(_:)),
            name: Notification.Name("NotificationTapped"),
            object: nil
        )
    }

    @objc private func handleNotificationTap(_ notification: Notification) {
        if let url = notification.userInfo?["url"] as? URL {
            navigator.route(url)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }
}
