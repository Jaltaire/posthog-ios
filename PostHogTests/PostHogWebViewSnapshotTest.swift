#if os(iOS)
    import Foundation
    @testable import PostHog
    import Testing
    import UIKit
    import WebKit

    @Suite("Web view snapshot source")
    @MainActor
    struct PostHogWebViewSnapshotSourceTests {
        let bounds = CGRect(x: 0, y: 0, width: 390, height: 844)

        func makeWindow() -> UIWindow {
            let window = UIWindow(frame: bounds)
            window.isHidden = false
            return window
        }

        func makeWebView(frame: CGRect? = nil) -> WKWebView {
            let webView = WKWebView(frame: frame ?? bounds)
            webView.isOpaque = false
            webView.backgroundColor = .systemBackground
            return webView
        }

        func makeContainer(frame: CGRect? = nil) -> UIView {
            UIView(frame: frame ?? bounds)
        }

        @Test("finds a web view that fills the window by itself")
        func webViewFillingTheWindow() {
            let window = makeWindow()
            let webView = makeWebView()
            window.addSubview(webView)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) === webView)
        }

        @Test("finds a web view held by containers that fill the window")
        func webViewInsideContainers() {
            let window = makeWindow()
            let outer = makeContainer()
            let inner = makeContainer()
            let webView = makeWebView()
            window.addSubview(outer)
            outer.addSubview(inner)
            inner.addSubview(webView)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) === webView)
        }

        @Test("finds nothing in a window without a web view")
        func windowWithoutWebView() {
            let window = makeWindow()
            window.addSubview(makeContainer())
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("finds nothing in a hidden window")
        func hiddenWindow() {
            let window = makeWindow()
            window.addSubview(makeWebView())
            window.isHidden = true
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("finds nothing in a faded window")
        func fadedWindow() {
            let window = makeWindow()
            window.addSubview(makeWebView())
            window.alpha = 0.5
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("finds nothing when a visible view lies above the web view")
        func viewAboveWebView() {
            let window = makeWindow()
            window.addSubview(makeWebView())
            window.addSubview(UIView(frame: CGRect(x: 10, y: 10, width: 40, height: 40)))
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("finds nothing when a view above the web view sits in a later container")
        func viewAboveWebViewInLaterContainer() {
            let window = makeWindow()
            let first = makeContainer()
            first.addSubview(makeWebView())
            let second = makeContainer()
            second.addSubview(UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 20)))
            window.addSubview(first)
            window.addSubview(second)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("ignores a hidden view above the web view")
        func hiddenViewAboveWebView() {
            let window = makeWindow()
            let webView = makeWebView()
            window.addSubview(webView)
            let cover = UIView(frame: bounds)
            cover.isHidden = true
            window.addSubview(cover)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) === webView)
        }

        @Test("ignores a transparent view above the web view")
        func transparentViewAboveWebView() {
            let window = makeWindow()
            let webView = makeWebView()
            window.addSubview(webView)
            let cover = UIView(frame: bounds)
            cover.alpha = 0
            window.addSubview(cover)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) === webView)
        }

        @Test("ignores views behind the web view")
        func viewsBehindWebView() {
            let window = makeWindow()
            window.addSubview(UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 20)))
            let webView = makeWebView()
            window.addSubview(webView)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) === webView)
        }

        @Test("ignores the web view's own subviews")
        func webViewSubviews() {
            let window = makeWindow()
            let webView = makeWebView()
            window.addSubview(webView)
            webView.addSubview(UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 20)))
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) === webView)
        }

        @Test("takes the frontmost of two web views that fill the window")
        func frontmostOfTwoWebViews() {
            let window = makeWindow()
            window.addSubview(makeWebView())
            let front = makeWebView()
            window.addSubview(front)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) === front)
        }

        @Test("finds nothing when a smaller web view lies above one that fills the window")
        func smallerWebViewAboveFullOne() {
            let window = makeWindow()
            window.addSubview(makeWebView())
            window.addSubview(makeWebView(frame: CGRect(x: 0, y: 0, width: 200, height: 200)))
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("finds nothing when the web view is smaller than the window")
        func smallerWebView() {
            let window = makeWindow()
            window.addSubview(makeWebView(frame: bounds.insetBy(dx: 0, dy: 20)))
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("finds nothing when the web view reaches beyond the window")
        func largerWebView() {
            let window = makeWindow()
            window.addSubview(makeWebView(frame: bounds.insetBy(dx: 0, dy: -20)))
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("accepts a web view whose edges are within half a pixel of the window's")
        func subPixelOffset() {
            let window = makeWindow()
            let offset = 0.4 / window.screen.scale
            let webView = makeWebView(frame: bounds.offsetBy(dx: offset, dy: -offset))
            window.addSubview(webView)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) === webView)
        }

        @Test("finds nothing when the web view is a pixel away from the window's edge")
        func onePixelOffset() {
            let window = makeWindow()
            let offset = 1 / window.screen.scale
            window.addSubview(makeWebView(frame: bounds.offsetBy(dx: offset, dy: 0)))
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("finds nothing when the web view is faded")
        func fadedWebView() {
            let window = makeWindow()
            let webView = makeWebView()
            webView.alpha = 0.5
            window.addSubview(webView)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("finds nothing when the web view is masked")
        func maskedWebView() {
            let window = makeWindow()
            let webView = makeWebView()
            webView.layer.mask = CALayer()
            window.addSubview(webView)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("finds nothing when the web view's corners are clipped")
        func roundedWebView() {
            let window = makeWindow()
            let webView = makeWebView()
            webView.layer.cornerRadius = 12
            webView.layer.masksToBounds = true
            window.addSubview(webView)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("accepts rounded corners that do not clip the web view")
        func roundedUnclippedWebView() {
            let window = makeWindow()
            let webView = makeWebView()
            webView.layer.cornerRadius = 12
            webView.layer.masksToBounds = false
            window.addSubview(webView)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) === webView)
        }

        @Test("finds nothing when a transparent web view could show what lies behind it")
        func transparentWebView() {
            let window = makeWindow()
            let webView = makeWebView()
            webView.backgroundColor = .clear
            window.addSubview(webView)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("finds nothing when a transparent web view has no background colour")
        func webViewWithoutBackground() {
            let window = makeWindow()
            let webView = makeWebView()
            webView.backgroundColor = nil
            window.addSubview(webView)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("finds nothing when a transparent web view has a translucent background")
        func webViewWithTranslucentBackground() {
            let window = makeWindow()
            let webView = makeWebView()
            webView.backgroundColor = UIColor.white.withAlphaComponent(0.9)
            window.addSubview(webView)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("accepts an opaque web view without a background colour")
        func opaqueWebView() {
            let window = makeWindow()
            let webView = makeWebView()
            webView.backgroundColor = nil
            webView.isOpaque = true
            window.addSubview(webView)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) === webView)
        }

        @Test("finds nothing when a container fades the web view")
        func fadedContainer() {
            let window = makeWindow()
            let container = makeContainer()
            container.alpha = 0.5
            container.addSubview(makeWebView())
            window.addSubview(container)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("finds nothing when a container masks the web view")
        func maskedContainer() {
            let window = makeWindow()
            let container = makeContainer()
            container.layer.mask = CALayer()
            container.addSubview(makeWebView())
            window.addSubview(container)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("finds nothing when a smaller container clips the web view")
        func clippingContainer() {
            let window = makeWindow()
            let container = makeContainer(frame: CGRect(x: 0, y: 0, width: 390, height: 400))
            container.clipsToBounds = true
            container.addSubview(makeWebView())
            window.addSubview(container)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) == nil)
        }

        @Test("accepts a smaller container that does not clip the web view")
        func smallerUnclippedContainer() {
            let window = makeWindow()
            let container = makeContainer(frame: CGRect(x: 0, y: 0, width: 390, height: 400))
            let webView = makeWebView()
            container.addSubview(webView)
            window.addSubview(container)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) === webView)
        }

        @Test("accepts a clipping container that covers the window")
        func clippingContainerCoveringWindow() {
            let window = makeWindow()
            let container = makeContainer()
            container.clipsToBounds = true
            let webView = makeWebView()
            container.addSubview(webView)
            window.addSubview(container)
            #expect(PostHogWebViewSnapshot.webViewShowingWindow(window) === webView)
        }

        @Test("draws the window when web view snapshots are off")
        func sourceWhenDisabled() {
            let window = makeWindow()
            window.addSubview(makeWebView())
            #expect(PostHogWebViewSnapshot.source(for: window, webViewSnapshots: false, onMainThread: true) == .windowHierarchy)
        }

        @Test("draws the window when capturing off the main thread")
        func sourceOffMainThread() {
            let window = makeWindow()
            window.addSubview(makeWebView())
            #expect(PostHogWebViewSnapshot.source(for: window, webViewSnapshots: true, onMainThread: false) == .windowHierarchy)
        }

        @Test("draws the window when it shows more than a web view")
        func sourceWithOverlay() {
            let window = makeWindow()
            window.addSubview(makeWebView())
            window.addSubview(UIView(frame: bounds))
            #expect(PostHogWebViewSnapshot.source(for: window, webViewSnapshots: true, onMainThread: true) == .windowHierarchy)
        }

        @Test("snapshots the web view when it is all the window shows")
        func sourceWithWebView() {
            let window = makeWindow()
            let webView = makeWebView()
            window.addSubview(webView)
            #expect(PostHogWebViewSnapshot.source(for: window, webViewSnapshots: true, onMainThread: true) == .webView(webView))
        }
    }

    @Suite("Web view snapshotter")
    @MainActor
    struct PostHogWebViewSnapshotterTests {
        final class Recorder {
            var requested: [WKWebView] = []
            var completions: [(UIImage?) -> Void] = []
            var delays: [TimeInterval] = []
            var scheduled: [() -> Void] = []
            var images: [UIImage] = []
            var failures = 0

            func snapshotter(timeout: TimeInterval = 5) -> PostHogWebViewSnapshotter {
                PostHogWebViewSnapshotter(
                    snapshot: { webView, completion in
                        self.requested.append(webView)
                        self.completions.append(completion)
                    },
                    schedule: { delay, work in
                        self.delays.append(delay)
                        self.scheduled.append(work)
                    },
                    timeout: timeout
                )
            }

            func capture(_ snapshotter: PostHogWebViewSnapshotter, _ webView: WKWebView) {
                snapshotter.capture(
                    webView,
                    onImage: { self.images.append($0) },
                    onFailure: { self.failures += 1 }
                )
            }
        }

        func makeImage() -> UIImage {
            UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
                UIColor.red.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
            }
        }

        @Test("asks WebKit for the given web view and arms the timeout")
        func requestsSnapshotAndArmsTimeout() {
            let recorder = Recorder()
            let webView = WKWebView()
            recorder.capture(recorder.snapshotter(timeout: 3), webView)
            #expect(recorder.requested.count == 1)
            #expect(recorder.requested.first === webView)
            #expect(recorder.delays == [3])
            #expect(recorder.images.isEmpty)
            #expect(recorder.failures == 0)
        }

        @Test("hands over an image that arrives in time, once")
        func imageBeforeTimeout() {
            let recorder = Recorder()
            recorder.capture(recorder.snapshotter(), WKWebView())
            let image = makeImage()
            recorder.completions[0](image)
            recorder.scheduled[0]()
            #expect(recorder.images.count == 1)
            #expect(recorder.images.first === image)
            #expect(recorder.failures == 0)
        }

        @Test("reports a failure when the timeout comes first, and drops the late image")
        func timeoutBeforeImage() {
            let recorder = Recorder()
            recorder.capture(recorder.snapshotter(), WKWebView())
            recorder.scheduled[0]()
            recorder.completions[0](makeImage())
            #expect(recorder.images.isEmpty)
            #expect(recorder.failures == 1)
        }

        @Test("reports a failure when WebKit returns no image")
        func missingImage() {
            let recorder = Recorder()
            recorder.capture(recorder.snapshotter(), WKWebView())
            recorder.completions[0](nil)
            recorder.scheduled[0]()
            #expect(recorder.images.isEmpty)
            #expect(recorder.failures == 1)
        }

        @Test("reports a failure when WebKit returns an empty image")
        func emptyImage() {
            let recorder = Recorder()
            recorder.capture(recorder.snapshotter(), WKWebView())
            recorder.completions[0](UIImage())
            recorder.scheduled[0]()
            #expect(recorder.images.isEmpty)
            #expect(recorder.failures == 1)
        }

        @Test("keeps each capture's outcome to itself")
        func separateCaptures() {
            let recorder = Recorder()
            let snapshotter = recorder.snapshotter()
            recorder.capture(snapshotter, WKWebView())
            recorder.capture(snapshotter, WKWebView())
            recorder.scheduled[0]()
            recorder.completions[1](makeImage())
            recorder.completions[0](makeImage())
            recorder.scheduled[1]()
            #expect(recorder.images.count == 1)
            #expect(recorder.failures == 1)
        }

        @Test("uses the shared timeout by default")
        func defaultTimeout() {
            var delays: [TimeInterval] = []
            let snapshotter = PostHogWebViewSnapshotter(
                snapshot: { _, _ in },
                schedule: { delay, _ in delays.append(delay) }
            )
            snapshotter.capture(WKWebView(), onImage: { _ in }, onFailure: {})
            #expect(delays == [PostHogWebViewSnapshot.timeout])
        }

        final class RepliedWebView: WKWebView {
            var configurations: [WKSnapshotConfiguration?] = []
            var reply: (UIImage?, Error?) = (nil, nil)

            override func takeSnapshot(
                with snapshotConfiguration: WKSnapshotConfiguration?,
                completionHandler: @escaping @MainActor (UIImage?, Error?) -> Void
            ) {
                configurations.append(snapshotConfiguration)
                completionHandler(reply.0, reply.1)
            }
        }

        @Test("asks WebKit for a snapshot taken after the web view's next update, and hands over its image")
        func webKitSnapshotImage() {
            let webView = RepliedWebView()
            let image = makeImage()
            webView.reply = (image, nil)
            var delivered: [UIImage?] = []
            PostHogWebViewSnapshotter.webKitSnapshot(webView) { delivered.append($0) }
            #expect(webView.configurations.count == 1)
            #expect(webView.configurations.first??.afterScreenUpdates == true)
            #expect(webView.configurations.first??.rect.isNull == true)
            #expect(delivered.count == 1)
            #expect(delivered.first.flatMap { $0 } === image)
        }

        @Test("hands over no image when WebKit reports an error")
        func webKitSnapshotError() {
            let webView = RepliedWebView()
            webView.reply = (nil, NSError(domain: WKErrorDomain, code: WKError.unknown.rawValue))
            var delivered: [UIImage?] = []
            PostHogWebViewSnapshotter.webKitSnapshot(webView) { delivered.append($0) }
            #expect(delivered.count == 1)
            #expect(delivered.first.flatMap { $0 } == nil)
        }
    }

    @Suite("Exactly-once flag")
    struct PostHogOnceTests {
        @Test("lets only the first caller through")
        func firstCallerOnly() {
            let once = PostHogOnce()
            #expect(once.claim())
            #expect(!once.claim())
            #expect(!once.claim())
        }

        @Test("lets exactly one of many concurrent callers through")
        func concurrentCallers() {
            let once = PostHogOnce()
            let lock = NSLock()
            var claims = 0
            DispatchQueue.concurrentPerform(iterations: 64) { _ in
                if once.claim() {
                    lock.withLock { claims += 1 }
                }
            }
            #expect(claims == 1)
        }
    }

    @Suite("Web view snapshot configuration")
    struct PostHogWebViewSnapshotConfigTests {
        @Test("is off by default")
        func offByDefault() {
            #expect(!PostHogSessionReplayConfig().screenshotModeWebViewSnapshot)
        }
    }
#endif
