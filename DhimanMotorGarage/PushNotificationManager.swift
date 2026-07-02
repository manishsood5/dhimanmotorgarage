import Foundation
import UIKit
import OneSignalFramework

extension Notification.Name {
    static let didUpdatePushToken = Notification.Name("didUpdatePushToken")
}

private let oneSignalAppID = "c4774a4c-8624-454a-91cc-5ddf557edb86"

enum PushKeys {
    static let deviceToken = "PushNotificationDeviceToken"
}

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        OneSignal.initialize(oneSignalAppID, withLaunchOptions: launchOptions)
        return true
    }

    static func requestSystemPushPermission() {
        OneSignal.Notifications.requestPermission({ accepted in
            #if DEBUG
            print("OneSignal notification permission accepted: \(accepted)")
            #endif
            if accepted {
                broadcastTokenWhenAvailable()
            }
        }, fallbackToSettings: true)
    }

    private static func broadcastTokenWhenAvailable() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let token = OneSignal.User.pushSubscription.token {
                UserDefaults.standard.set(token, forKey: PushKeys.deviceToken)
                NotificationCenter.default.post(name: .didUpdatePushToken, object: token)
            }
        }
    }
}
