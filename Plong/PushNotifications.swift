import UIKit
import UserNotifications

/// Bridges the APNs device-token callback (UIKit, fires independently of any
/// screen) into the app's own API. `session` is handed in once by ContentView,
/// since by the time registration completes the user is already logged in.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static var session: Session?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Without this, iOS silently drops the banner for a push that arrives while the
        // app is open — e.g. a manager watching the crowd count get the "crowded" alert.
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        guard let accessToken = AppDelegate.session?.accessToken else { return }
        Task { try? await API.registerPushToken(token, token: accessToken) }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("push registration failed: \(error)")
    }
}

enum PushNotifications {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
        }
    }
}
