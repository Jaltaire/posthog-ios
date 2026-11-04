#if os(iOS)
    import UIKit
    import WebKit

    enum PostHogScreenshotSource: Equatable {
        case windowHierarchy
        case webView(WKWebView)
    }

    enum PostHogWebViewSnapshot {
        static let timeout: TimeInterval = 5

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

    final class PostHogWebViewSnapshotter {
        typealias Snapshot = (WKWebView, @escaping (UIImage?) -> Void) -> Void
        typealias Schedule = (TimeInterval, @escaping () -> Void) -> Void

        private let snapshot: Snapshot
        private let schedule: Schedule
        private let timeout: TimeInterval

        init(
            snapshot: @escaping Snapshot = PostHogWebViewSnapshotter.webKitSnapshot,
            schedule: @escaping Schedule = PostHogWebViewSnapshotter.mainQueueSchedule,
            timeout: TimeInterval = PostHogWebViewSnapshot.timeout
        ) {
            self.snapshot = snapshot
            self.schedule = schedule
            self.timeout = timeout
        }

        func capture(_ webView: WKWebView, onImage: @escaping (UIImage) -> Void, onFailure: @escaping () -> Void) {
            let outcome = PostHogOnce()
            schedule(timeout) {
                guard outcome.claim() else {
                    return
                }
                hedgeLog("[Session Replay] The web view snapshot did not arrive in time. Skipping this capture...")
                onFailure()
            }
            snapshot(webView) { image in
                guard outcome.claim() else {
                    return
                }
                guard let image, image.size.hasSize() else {
                    onFailure()
                    return
                }
                onImage(image)
            }
        }

        static func webKitSnapshot(_ webView: WKWebView, _ completion: @escaping (UIImage?) -> Void) {
            let configuration = WKSnapshotConfiguration()
            configuration.afterScreenUpdates = true
            webView.takeSnapshot(with: configuration) { image, error in
                if let error {
                    hedgeLog("[Session Replay] WebKit could not snapshot the web view: \(error).")
                }
                completion(image)
            }
        }

        static func mainQueueSchedule(_ delay: TimeInterval, _ work: @escaping () -> Void) {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        }
    }

    final class PostHogOnce {
        private let lock = NSLock()
        private var claimed = false

        func claim() -> Bool {
            lock.withLock {
                if claimed {
                    return false
                }
                claimed = true
                return true
            }
        }
    }
#endif
