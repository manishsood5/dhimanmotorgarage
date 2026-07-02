import Foundation
import UIKit
import OneSignalFramework

extension Notification.Name {
    static let didUpdatePushToken = Notification.Name("didUpdatePushToken")
    static let didReceiveNotificationURL = Notification.Name("didReceiveNotificationURL")
}

private let oneSignalAppID = "c4774a4c-8624-454a-91cc-5ddf557edb86"

enum PushKeys {
    static let deviceToken = "PushNotificationDeviceToken"
}

/// Holds a deep-link URL from a notification tap until the WebView is ready to
/// consume it (needed for cold launches where the click fires before the WebView exists).
enum PendingNavigation {
    static var url: URL?

    static func consume() -> URL? {
        defer { url = nil }
        return url
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, OSNotificationClickListener {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        OneSignal.initialize(oneSignalAppID, withLaunchOptions: launchOptions)
        OneSignal.Notifications.addClickListener(self)
        return true
    }

    // Launch URLs are suppressed via `OneSignal_suppress_launch_urls` in Info.plist,
    // so we route the tapped notification's URL into the in-app WebView instead of Safari.
    func onClick(event: OSNotificationClickEvent) {
        let notification = event.notification

        var urlString = notification.launchURL
        if urlString == nil || urlString?.isEmpty == true {
            let data = notification.additionalData
            urlString = data?["ONESIGNAL_URL"] as? String ?? data?["url"] as? String
        }

        guard let urlString,
              let url = URL(string: urlString),
              url.scheme?.hasPrefix("http") == true else {
            return
        }

        PendingNavigation.url = url
        NotificationCenter.default.post(name: .didReceiveNotificationURL, object: url)
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
