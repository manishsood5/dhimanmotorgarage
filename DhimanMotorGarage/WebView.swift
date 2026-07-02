import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var progress: Double
    @Binding var navigateTo: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        // Disable long-press callout and text selection everywhere except inputs.
        let css = """
            * { -webkit-touch-callout: none !important; -webkit-user-select: none !important; user-select: none !important; }
            input, textarea, [contenteditable] { -webkit-user-select: text !important; user-select: text !important; }
            """
        let disableLongPressJS = """
            (function() {
                var style = document.createElement('style');
                style.textContent = `\(css)`;
                document.head.appendChild(style);
                document.addEventListener('contextmenu', function(e) { e.preventDefault(); }, true);
            })();
            """
        let script = WKUserScript(source: disableLongPressJS, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(script)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = false
        webView.isOpaque = true
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic

        context.coordinator.webView = webView
        context.coordinator.startObserving(webView)
        context.coordinator.load(url: url, in: webView)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let target = navigateTo {
            webView.load(URLRequest(url: target))
            DispatchQueue.main.async { navigateTo = nil }
        }
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.stopObserving()
        coordinator.stopObservingPushToken()
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebView
        weak var webView: WKWebView?
        private var progressObservation: NSKeyValueObservation?
        private var pushTokenObserver: NSObjectProtocol?
        private let pushTokenDefaultsKey = PushKeys.deviceToken

        init(parent: WebView) {
            self.parent = parent
        }

        func startObserving(_ webView: WKWebView) {
            progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.parent.progress = webView.estimatedProgress
                }
            }
            startObservingPushToken()
        }

        func stopObserving() {
            progressObservation?.invalidate()
            progressObservation = nil
        }

        func startObservingPushToken() {
            pushTokenObserver = NotificationCenter.default.addObserver(
                forName: .didUpdatePushToken,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let token = notification.object as? String else { return }
                self?.injectPushTokenIntoWebApp(token)
            }
        }

        func stopObservingPushToken() {
            if let pushTokenObserver {
                NotificationCenter.default.removeObserver(pushTokenObserver)
            }
            pushTokenObserver = nil
        }

        func load(url: URL, in webView: WKWebView) {
            parent.isLoading = true
            webView.load(URLRequest(url: url))
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.progress = 1.0
            if let token = UserDefaults.standard.string(forKey: pushTokenDefaultsKey) {
                injectPushTokenIntoWebApp(token)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let requestURL = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            let scheme = requestURL.scheme?.lowercased() ?? ""

            if ["tel", "mailto", "sms", "maps", "itms-apps", "itms"].contains(scheme) {
                UIApplication.shared.open(requestURL)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }

        // MARK: - JavaScript dialog handlers

        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            topViewController()?.present(alert, animated: true)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
            topViewController()?.present(alert, animated: true)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptTextInputPanelWithPrompt prompt: String,
            defaultText: String?,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (String?) -> Void
        ) {
            let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
            alert.addTextField { $0.text = defaultText }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler(alert.textFields?.first?.text)
            })
            topViewController()?.present(alert, animated: true)
        }

        private func topViewController() -> UIViewController? {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
                return nil
            }
            var top = root
            while let presented = top.presentedViewController { top = presented }
            return top
        }

        private func injectPushTokenIntoWebApp(_ token: String) {
            guard let webView else { return }
            let escapedToken = token.replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
            let js = """
                window.__iosPushToken = '\(escapedToken)';
                localStorage.setItem('iosPushToken', '\(escapedToken)');
                window.dispatchEvent(new CustomEvent('ios-push-token', { detail: { token: '\(escapedToken)' } }));
            """
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}
