#if os(iOS)
    import UIKit
    import WebKit

    enum PostHogScreenshotSource: Equatable {
        case windowHierarchy
        case webView(WKWebView)
    }

    enum PostHogWebViewSnapshot {
        static func screenshot(
            of window: UIWindow,
            webViewSnapshots: Bool,
            onMainThread: Bool,
            snapshotter: PostHogWebViewSnapshotter<WKWebView>,
            draw: (UIWindow) -> UIImage?
        ) -> UIImage? {
            if case let .webView(webView) = source(for: window, webViewSnapshots: webViewSnapshots, onMainThread: onMainThread),
               let image = snapshotter.image(of: webView)
            {
                return image
            }
            return draw(window)
        }

        static func source(
            for window: UIWindow,
            webViewSnapshots: Bool,
            onMainThread: Bool
        ) -> PostHogScreenshotSource {
            guard webViewSnapshots, onMainThread, let webView = webViewShowingWindow(window) else {
                return .windowHierarchy
            }
            return .webView(webView)
        }

        static func webViewShowingWindow(_ window: UIWindow) -> WKWebView? {
            guard window.isVisible(), isWhole(window) else {
                return nil
            }
            let tolerance = 0.5 / max(window.screen.scale, 1)
            var frontmost: WKWebView?
            func visit(_ view: UIView, throughWholeAncestors: Bool) {
                for subview in view.subviews where subview.isVisible() {
                    if let webView = subview as? WKWebView {
                        let showsWindow = throughWholeAncestors
                            && isWhole(webView)
                            && paintsOpaquely(webView)
                            && covers(webView, exactly: window, tolerance: tolerance)
                        frontmost = showsWindow ? webView : nil
                        continue
                    }
                    frontmost = nil
                    visit(subview, throughWholeAncestors: throughWholeAncestors && passesWindowThrough(subview, window))
                }
            }
            visit(window, throughWholeAncestors: true)
            return frontmost
        }

        private static func isWhole(_ view: UIView) -> Bool {
            view.alpha >= 1 && view.layer.mask == nil
        }

        private static func passesWindowThrough(_ view: UIView, _ window: UIWindow) -> Bool {
            guard isWhole(view) else {
                return false
            }
            return !view.clipsToBounds || view.toAbsoluteRect(window).contains(window.bounds)
        }

        private static func paintsOpaquely(_ webView: WKWebView) -> Bool {
            if webView.layer.cornerRadius > 0, webView.layer.masksToBounds {
                return false
            }
            if webView.isOpaque {
                return true
            }
            guard let background = webView.backgroundColor?.resolvedColor(with: webView.traitCollection) else {
                return false
            }
            return background.cgColor.alpha >= 1
        }

        private static func covers(_ webView: WKWebView, exactly window: UIWindow, tolerance: CGFloat) -> Bool {
            let frame = webView.toAbsoluteRect(window)
            let bounds = window.bounds
            return abs(frame.minX - bounds.minX) <= tolerance
                && abs(frame.minY - bounds.minY) <= tolerance
                && abs(frame.maxX - bounds.maxX) <= tolerance
                && abs(frame.maxY - bounds.maxY) <= tolerance
        }
    }

    final class PostHogWebViewSnapshotter<WebView: AnyObject> {
        typealias Snapshot = (WebView, @escaping (UIImage?) -> Void) -> Void

        private let snapshot: Snapshot
        private weak var unanswered: WebView?

        init(snapshot: @escaping Snapshot) {
            self.snapshot = snapshot
        }

        var isAwaitingAnswer: Bool {
            unanswered != nil
        }

        func image(of webView: WebView) -> UIImage? {
            guard unanswered == nil else {
                return nil
            }
            var asking = true
            var answered = false
            var answer: UIImage?
            snapshot(webView) { [weak self, weak webView] image in
                if asking {
                    answered = true
                    answer = image
                    return
                }
                guard let self, self.unanswered === webView else {
                    return
                }
                self.unanswered = nil
            }
            asking = false
            guard answered else {
                hedgeLog("[Session Replay] WebKit did not snapshot the web view at once. Drawing the window instead...")
                unanswered = webView
                return nil
            }
            guard let answer, answer.size.hasSize() else {
                return nil
            }
            return answer
        }
    }

    extension PostHogWebViewSnapshotter where WebView == WKWebView {
        convenience init() {
            self.init(snapshot: PostHogWebViewSnapshotter.webKitSnapshot)
        }

        static func webKitSnapshot(_ webView: WKWebView, _ completion: @escaping (UIImage?) -> Void) {
            let configuration = WKSnapshotConfiguration()
            configuration.afterScreenUpdates = false
            webView.takeSnapshot(with: configuration) { image, error in
                if let error {
                    hedgeLog("[Session Replay] WebKit could not snapshot the web view: \(error).")
                }
                completion(image)
            }
        }
    }
#endif
