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

        @Test("finds nothing when a transparent web view has no background color")
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

        @Test("accepts an opaque web view without a background color")
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

    enum SnapshotReply {
        case during(UIImage?)
        case later
    }

    final class SnapshotRecorder<Target: AnyObject> {
        var reply: SnapshotReply = .later
        var requests: [ObjectIdentifier] = []
        var completions: [(UIImage?) -> Void] = []

        func snapshotter() -> PostHogWebViewSnapshotter<Target> {
            PostHogWebViewSnapshotter { target, completion in
                self.requests.append(ObjectIdentifier(target))
                switch self.reply {
                case let .during(image):
                    completion(image)
                case .later:
                    self.completions.append(completion)
                }
            }
        }
    }

    func makeSnapshotImage(_ color: UIColor = .red) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }

    @Suite("Web view snapshotter")
    @MainActor
    struct PostHogWebViewSnapshotterTests {
        @Test("hands over the image given during the call")
        func imageDuringCall() {
            let recorder = SnapshotRecorder<NSObject>()
            let image = makeSnapshotImage()
            recorder.reply = .during(image)
            let snapshotter = recorder.snapshotter()
            let target = NSObject()
            #expect(snapshotter.image(of: target) === image)
            #expect(recorder.requests == [ObjectIdentifier(target)])
            #expect(!snapshotter.isAwaitingAnswer)
        }

        @Test("asks again on every capture answered during the call")
        func asksOnEveryAnsweredCapture() {
            let recorder = SnapshotRecorder<NSObject>()
            recorder.reply = .during(makeSnapshotImage())
            let snapshotter = recorder.snapshotter()
            let target = NSObject()
            _ = snapshotter.image(of: target)
            _ = snapshotter.image(of: target)
            _ = snapshotter.image(of: target)
            #expect(recorder.requests.count == 3)
            #expect(!snapshotter.isAwaitingAnswer)
        }

        @Test("hands over nothing when no image is given during the call, and waits for nothing")
        func noImageDuringCall() {
            let recorder = SnapshotRecorder<NSObject>()
            recorder.reply = .during(nil)
            let snapshotter = recorder.snapshotter()
            let target = NSObject()
            #expect(snapshotter.image(of: target) == nil)
            #expect(!snapshotter.isAwaitingAnswer)
            #expect(recorder.requests == [ObjectIdentifier(target)])
        }

        @Test("hands over nothing when an empty image is given during the call, and waits for nothing")
        func emptyImageDuringCall() {
            let recorder = SnapshotRecorder<NSObject>()
            recorder.reply = .during(UIImage())
            let snapshotter = recorder.snapshotter()
            let target = NSObject()
            #expect(snapshotter.image(of: target) == nil)
            #expect(!snapshotter.isAwaitingAnswer)
            #expect(recorder.requests == [ObjectIdentifier(target)])
        }

        @Test("hands over nothing when nothing answers during the call, and awaits the answer")
        func noAnswerDuringCall() {
            let recorder = SnapshotRecorder<NSObject>()
            let snapshotter = recorder.snapshotter()
            let target = NSObject()
            #expect(snapshotter.image(of: target) == nil)
            #expect(snapshotter.isAwaitingAnswer)
            #expect(recorder.requests == [ObjectIdentifier(target)])
        }

        @Test("asks nothing more while an answer is awaited")
        func noSecondRequestWhileAwaiting() {
            let recorder = SnapshotRecorder<NSObject>()
            let snapshotter = recorder.snapshotter()
            let target = NSObject()
            _ = snapshotter.image(of: target)
            recorder.reply = .during(makeSnapshotImage())
            #expect(snapshotter.image(of: target) == nil)
            #expect(snapshotter.image(of: NSObject()) == nil)
            #expect(recorder.requests.count == 1)
            #expect(recorder.completions.count == 1)
        }

        @Test("asks again once the late answer arrives, and drops the late image")
        func asksAgainAfterLateAnswer() {
            let recorder = SnapshotRecorder<NSObject>()
            let snapshotter = recorder.snapshotter()
            let target = NSObject()
            _ = snapshotter.image(of: target)
            recorder.completions[0](makeSnapshotImage(.blue))
            #expect(!snapshotter.isAwaitingAnswer)
            let image = makeSnapshotImage()
            recorder.reply = .during(image)
            #expect(snapshotter.image(of: target) === image)
            #expect(recorder.requests.count == 2)
        }

        @Test("asks again once a late answer without an image arrives")
        func asksAgainAfterLateFailure() {
            let recorder = SnapshotRecorder<NSObject>()
            let snapshotter = recorder.snapshotter()
            let target = NSObject()
            _ = snapshotter.image(of: target)
            recorder.completions[0](nil)
            #expect(!snapshotter.isAwaitingAnswer)
            #expect(snapshotter.image(of: target) == nil)
            #expect(recorder.requests.count == 2)
        }

        @Test("asks again once the web view it awaits is gone")
        func asksAgainOnceWebViewIsGone() {
            let recorder = SnapshotRecorder<NSObject>()
            let snapshotter = recorder.snapshotter()
            weak var released: NSObject?
            autoreleasepool {
                let target = NSObject()
                released = target
                _ = snapshotter.image(of: target)
            }
            #expect(released == nil)
            #expect(!snapshotter.isAwaitingAnswer)
            let image = makeSnapshotImage()
            recorder.reply = .during(image)
            #expect(snapshotter.image(of: NSObject()) === image)
            #expect(recorder.requests.count == 2)
        }

        @Test("keeps awaiting a web view when a gone one answers late")
        func lateAnswerFromGoneWebView() {
            let recorder = SnapshotRecorder<NSObject>()
            let snapshotter = recorder.snapshotter()
            weak var released: NSObject?
            autoreleasepool {
                let target = NSObject()
                released = target
                _ = snapshotter.image(of: target)
            }
            #expect(released == nil)
            let current = NSObject()
            #expect(snapshotter.image(of: current) == nil)
            #expect(snapshotter.isAwaitingAnswer)
            recorder.completions[0](makeSnapshotImage())
            #expect(snapshotter.isAwaitingAnswer)
            recorder.completions[1](nil)
            #expect(!snapshotter.isAwaitingAnswer)
        }

        @Test("ignores a second late answer to the same request")
        func secondLateAnswer() {
            let recorder = SnapshotRecorder<NSObject>()
            let snapshotter = recorder.snapshotter()
            let first = NSObject()
            _ = snapshotter.image(of: first)
            recorder.completions[0](nil)
            let second = NSObject()
            _ = snapshotter.image(of: second)
            #expect(snapshotter.isAwaitingAnswer)
            recorder.completions[0](nil)
            #expect(snapshotter.isAwaitingAnswer)
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

        final class DeferringWebView: WKWebView {
            var handlers: [@MainActor (UIImage?, Error?) -> Void] = []

            override func takeSnapshot(
                with _: WKSnapshotConfiguration?,
                completionHandler: @escaping @MainActor (UIImage?, Error?) -> Void
            ) {
                handlers.append(completionHandler)
            }
        }

        @Test("asks WebKit for a snapshot of what the web view shows now, without waiting for its next update")
        func webKitSnapshotConfiguration() {
            let webView = RepliedWebView()
            webView.reply = (makeSnapshotImage(), nil)
            PostHogWebViewSnapshotter<WKWebView>.webKitSnapshot(webView) { _ in }
            #expect(webView.configurations.count == 1)
            #expect(webView.configurations.first??.afterScreenUpdates == false)
            #expect(webView.configurations.first??.rect.isNull == true)
        }

        @Test("hands over WebKit's image")
        func webKitSnapshotImage() {
            let webView = RepliedWebView()
            let image = makeSnapshotImage()
            webView.reply = (image, nil)
            var delivered: [UIImage?] = []
            PostHogWebViewSnapshotter<WKWebView>.webKitSnapshot(webView) { delivered.append($0) }
            #expect(delivered.count == 1)
            #expect(delivered.first.flatMap { $0 } === image)
        }

        @Test("hands over no image when WebKit reports an error")
        func webKitSnapshotError() {
            let webView = RepliedWebView()
            webView.reply = (nil, NSError(domain: WKErrorDomain, code: WKError.unknown.rawValue))
            var delivered: [UIImage?] = []
            PostHogWebViewSnapshotter<WKWebView>.webKitSnapshot(webView) { delivered.append($0) }
            #expect(delivered.count == 1)
            #expect(delivered.first.flatMap { $0 } == nil)
        }

        @Test("takes the image of a web view that answers during the call by default")
        func defaultSnapshotAnsweredDuringCall() {
            let webView = RepliedWebView()
            let image = makeSnapshotImage()
            webView.reply = (image, nil)
            let snapshotter = PostHogWebViewSnapshotter<WKWebView>()
            #expect(snapshotter.image(of: webView) === image)
            #expect(webView.configurations.count == 1)
            #expect(!snapshotter.isAwaitingAnswer)
        }

        @Test("awaits a web view that answers later by default, and asks again once it has")
        func defaultSnapshotAnsweredLater() {
            let webView = DeferringWebView()
            let snapshotter = PostHogWebViewSnapshotter<WKWebView>()
            #expect(snapshotter.image(of: webView) == nil)
            #expect(snapshotter.image(of: webView) == nil)
            #expect(webView.handlers.count == 1)
            #expect(snapshotter.isAwaitingAnswer)
            webView.handlers[0](makeSnapshotImage(), nil)
            #expect(!snapshotter.isAwaitingAnswer)
            #expect(snapshotter.image(of: webView) == nil)
            #expect(webView.handlers.count == 2)
        }
    }

    @Suite("Web view screenshot")
    @MainActor
    struct PostHogWebViewScreenshotTests {
        let bounds = CGRect(x: 0, y: 0, width: 390, height: 844)

        final class Drawer {
            var windows: [UIWindow] = []
            var image: UIImage? = makeSnapshotImage(.green)

            func draw(_ window: UIWindow) -> UIImage? {
                windows.append(window)
                return image
            }
        }

        func makeWindow(showingOnlyAWebView: Bool = true) -> UIWindow {
            let window = UIWindow(frame: bounds)
            window.isHidden = false
            let webView = WKWebView(frame: bounds)
            webView.isOpaque = true
            window.addSubview(webView)
            if !showingOnlyAWebView {
                window.addSubview(UIView(frame: CGRect(x: 10, y: 10, width: 40, height: 40)))
            }
            return window
        }

        func screenshot(
            _ window: UIWindow,
            webViewSnapshots: Bool = true,
            onMainThread: Bool = true,
            snapshotter: PostHogWebViewSnapshotter<WKWebView>,
            drawer: Drawer
        ) -> UIImage? {
            PostHogWebViewSnapshot.screenshot(
                of: window,
                webViewSnapshots: webViewSnapshots,
                onMainThread: onMainThread,
                snapshotter: snapshotter,
                draw: drawer.draw
            )
        }

        @Test("takes WebKit's image of a web view that is all the window shows, without drawing the window")
        func webKitImage() {
            let recorder = SnapshotRecorder<WKWebView>()
            let image = makeSnapshotImage()
            recorder.reply = .during(image)
            let drawer = Drawer()
            let window = makeWindow()
            #expect(screenshot(window, snapshotter: recorder.snapshotter(), drawer: drawer) === image)
            #expect(recorder.requests.count == 1)
            #expect(drawer.windows.isEmpty)
        }

        @Test("draws the window when WebKit does not answer during the capture")
        func drawsWithoutAnswer() {
            let recorder = SnapshotRecorder<WKWebView>()
            let drawer = Drawer()
            let window = makeWindow()
            #expect(screenshot(window, snapshotter: recorder.snapshotter(), drawer: drawer) === drawer.image)
            #expect(drawer.windows == [window])
        }

        @Test("draws every capture without asking WebKit while its answer is awaited, and asks again once it has answered")
        func drawsWhileAwaiting() {
            let recorder = SnapshotRecorder<WKWebView>()
            let snapshotter = recorder.snapshotter()
            let drawer = Drawer()
            let window = makeWindow()
            _ = screenshot(window, snapshotter: snapshotter, drawer: drawer)
            recorder.reply = .during(makeSnapshotImage())
            _ = screenshot(window, snapshotter: snapshotter, drawer: drawer)
            _ = screenshot(window, snapshotter: snapshotter, drawer: drawer)
            #expect(recorder.requests.count == 1)
            #expect(drawer.windows.count == 3)
            recorder.completions[0](nil)
            let image = makeSnapshotImage(.blue)
            recorder.reply = .during(image)
            #expect(screenshot(window, snapshotter: snapshotter, drawer: drawer) === image)
            #expect(recorder.requests.count == 2)
            #expect(drawer.windows.count == 3)
        }

        @Test("draws the window when WebKit gives no image")
        func drawsWithoutImage() {
            let recorder = SnapshotRecorder<WKWebView>()
            recorder.reply = .during(nil)
            let drawer = Drawer()
            let window = makeWindow()
            #expect(screenshot(window, snapshotter: recorder.snapshotter(), drawer: drawer) === drawer.image)
            #expect(drawer.windows == [window])
        }

        @Test("draws the window when WebKit gives an empty image")
        func drawsWithEmptyImage() {
            let recorder = SnapshotRecorder<WKWebView>()
            recorder.reply = .during(UIImage())
            let drawer = Drawer()
            let window = makeWindow()
            #expect(screenshot(window, snapshotter: recorder.snapshotter(), drawer: drawer) === drawer.image)
            #expect(drawer.windows == [window])
        }

        @Test("draws the window without asking WebKit when web view snapshots are off")
        func drawsWhenOff() {
            let recorder = SnapshotRecorder<WKWebView>()
            recorder.reply = .during(makeSnapshotImage())
            let drawer = Drawer()
            let window = makeWindow()
            #expect(screenshot(window, webViewSnapshots: false, snapshotter: recorder.snapshotter(), drawer: drawer) === drawer.image)
            #expect(recorder.requests.isEmpty)
            #expect(drawer.windows == [window])
        }

        @Test("draws the window without asking WebKit when capturing off the main thread")
        func drawsOffMainThread() {
            let recorder = SnapshotRecorder<WKWebView>()
            recorder.reply = .during(makeSnapshotImage())
            let drawer = Drawer()
            let window = makeWindow()
            #expect(screenshot(window, onMainThread: false, snapshotter: recorder.snapshotter(), drawer: drawer) === drawer.image)
            #expect(recorder.requests.isEmpty)
            #expect(drawer.windows == [window])
        }

        @Test("draws the window without asking WebKit when it shows more than a web view")
        func drawsWithOverlay() {
            let recorder = SnapshotRecorder<WKWebView>()
            recorder.reply = .during(makeSnapshotImage())
            let drawer = Drawer()
            let window = makeWindow(showingOnlyAWebView: false)
            #expect(screenshot(window, snapshotter: recorder.snapshotter(), drawer: drawer) === drawer.image)
            #expect(recorder.requests.isEmpty)
            #expect(drawer.windows == [window])
        }

        @Test("gives nothing when WebKit gives nothing and the window cannot be drawn")
        func nothingAtAll() {
            let recorder = SnapshotRecorder<WKWebView>()
            recorder.reply = .during(nil)
            let drawer = Drawer()
            drawer.image = nil
            #expect(screenshot(makeWindow(), snapshotter: recorder.snapshotter(), drawer: drawer) == nil)
            #expect(drawer.windows.count == 1)
        }
    }

    @Suite("Web view snapshot configuration")
    struct PostHogWebViewSnapshotConfigTests {
        @Test("is off by default")
        func offByDefault() {
            #expect(!PostHogSessionReplayConfig().screenshotModeWebViewSnapshot)
        }
    }

    @Suite("Web view snapshot capture", .serialized)
    @MainActor
    struct PostHogWebViewSnapshotCaptureTests {
        final class Snapshots {
            private let lock = NSLock()
            private var values: [[String: Any]] = []

            func record(_ event: PostHogEvent) {
                guard event.event == "$snapshot",
                      let data = event.properties["$snapshot_data"] as? [[String: Any]]
                else { return }
                lock.withLock { values.append(contentsOf: data) }
            }

            var screenshots: [[String: Any]] {
                lock.withLock {
                    values.filter { $0["type"] as? Int == 2 }
                        .compactMap { $0["data"] as? [String: Any] }
                        .flatMap { $0["wireframes"] as? [[String: Any]] ?? [] }
                        .filter { $0["type"] as? String == "screenshot" }
                }
            }
        }

        final class ReleasedWebView: WKWebView {
            var onRelease: (() -> Void)?

            deinit {
                onRelease?()
            }
        }

        struct Harness {
            let sdk: PostHogSDK
            let integration: PostHogReplayIntegration
            let snapshots: Snapshots
            let webKit: SnapshotRecorder<WKWebView>
            let window: UIWindow
            let webView: WKWebView
        }

        let bounds = CGRect(x: 0, y: 0, width: 200, height: 300)

        func makeHarness(webViewSnapshots: Bool = true, maskAllTextInputs: Bool = false) throws -> Harness {
            let config = PostHogConfig(projectToken: UUID().uuidString)
            config.sessionReplay = true
            config.sessionReplayConfig.screenshotMode = true
            config.sessionReplayConfig.screenshotModeWebViewSnapshot = webViewSnapshots
            config.sessionReplayConfig.maskAllTextInputs = maskAllTextInputs
            config.sessionReplayConfig.maskAllImages = false
            config.sessionReplayConfig.captureNetworkTelemetry = false
            config.disableReachabilityForTesting = true
            config.disableQueueTimerForTesting = true
            config.disableFlushOnBackgroundForTesting = true
            config.disableRemoteConfigForTesting = true
            config.preloadFeatureFlags = false
            config.captureApplicationLifecycleEvents = false
            config.captureScreenViews = false
            let snapshots = Snapshots()
            config.setBeforeSend { event in
                snapshots.record(event)
                return nil
            }
            PostHogStorage(config).setDictionary(forKey: .remoteConfig, contents: ["sessionRecording": ["endpoint": "/s/"]])
            PostHogReplayIntegration.clearInstalls()
            let sdk = PostHogSDK.with(config)
            let integration = try #require(sdk.getReplayIntegration())
            #expect(sdk.isSessionReplayActive())
            let webKit = SnapshotRecorder<WKWebView>()
            integration.webViewSnapshotter = webKit.snapshotter()

            let root = UIViewController()
            let window = UIWindow(frame: bounds)
            window.rootViewController = root
            window.makeKeyAndVisible()
            root.view.frame = window.bounds
            let webView = WKWebView(frame: bounds)
            webView.isOpaque = true
            root.view.addSubview(webView)
            return Harness(sdk: sdk, integration: integration, snapshots: snapshots, webKit: webKit, window: window, webView: webView)
        }

        func close(_ harness: Harness) {
            harness.window.isHidden = true
            harness.sdk.close()
        }

        func drainReplayQueue() async {
            await withCheckedContinuation { continuation in
                PostHogReplayIntegration.dispatchQueue.async { continuation.resume() }
            }
        }

        func redImage() -> UIImage {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            return UIGraphicsImageRenderer(size: bounds.size, format: format).image { context in
                UIColor.red.setFill()
                context.fill(bounds)
            }
        }

        func uploadedCenter(_ screenshot: [String: Any]) throws -> [UInt8] {
            let base64 = try #require(screenshot["base64"] as? String)
            let encoded = try #require(base64.split(separator: ",").last.map(String.init))
            let data = try #require(Data(base64Encoded: encoded))
            let image = try #require(UIImage(data: data)?.cgImage)
            var rgba = [UInt8](repeating: 0, count: 4)
            let context = try #require(CGContext(
                data: &rgba, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ))
            context.draw(image, in: CGRect(x: -image.width / 2, y: -image.height / 2, width: image.width, height: image.height))
            return Array(rgba.prefix(3))
        }

        func isRed(_ center: [UInt8]) -> Bool {
            center[0] > 200 && center[1] < 50 && center[2] < 50
        }

        func uploadsNoRed(_ harness: Harness) throws -> Bool {
            try harness.snapshots.screenshots.allSatisfy { try !isRed(uploadedCenter($0)) }
        }

        func capture(_ harness: Harness, episodeFirstFrame: Bool = false) -> Bool {
            harness.integration.captureBridgeSnapshot(episodeFirstFrame: episodeFirstFrame, window: harness.window)
        }

        @Test("asks WebKit for a window that shows only a web view, and uploads the image it gives during the capture")
        func uploadsWebKitSnapshot() async throws {
            let harness = try makeHarness()
            defer { close(harness) }
            harness.webKit.reply = .during(redImage())

            #expect(capture(harness))
            #expect(harness.webKit.requests == [ObjectIdentifier(harness.webView)])
            await drainReplayQueue()

            let screenshot = try #require(harness.snapshots.screenshots.first)
            #expect(try isRed(uploadedCenter(screenshot)))
        }

        @Test("masks the snapshot as it would mask a drawn window")
        func masksWebKitSnapshot() async throws {
            let harness = try makeHarness(maskAllTextInputs: true)
            defer { close(harness) }
            harness.webKit.reply = .during(redImage())

            #expect(capture(harness))
            await drainReplayQueue()

            let screenshot = try #require(harness.snapshots.screenshots.first)
            #expect(try uploadedCenter(screenshot).allSatisfy { $0 < 50 })
        }

        @Test("draws the window when WebKit gives no image during the capture, and drops the image that arrives later")
        func drawsWithoutAnswer() async throws {
            let harness = try makeHarness()
            defer { close(harness) }
            let drawable = harness.window.toImage(preferFidelityRenderer: true) != nil

            #expect(capture(harness) == drawable)
            #expect(harness.webKit.requests.count == 1)
            harness.webKit.completions[0](redImage())
            await drainReplayQueue()

            #expect(harness.snapshots.screenshots.count == (drawable ? 1 : 0))
            #expect(try uploadsNoRed(harness))
        }

        @Test("draws the window when WebKit gives an empty image during the capture")
        func drawsWithEmptyImage() async throws {
            let harness = try makeHarness()
            defer { close(harness) }
            harness.webKit.reply = .during(UIImage())
            let drawable = harness.window.toImage(preferFidelityRenderer: true) != nil

            #expect(capture(harness) == drawable)
            #expect(harness.webKit.requests.count == 1)
            await drainReplayQueue()

            #expect(harness.snapshots.screenshots.count == (drawable ? 1 : 0))
            #expect(!harness.integration.webViewSnapshotter.isAwaitingAnswer)
        }

        @Test("draws every capture without asking WebKit again while its answer is outstanding, and asks again once it has answered")
        func noSecondRequestWhileOutstanding() async throws {
            let harness = try makeHarness()
            defer { close(harness) }

            _ = capture(harness)
            harness.webKit.reply = .during(redImage())
            _ = capture(harness)
            _ = capture(harness)
            #expect(harness.webKit.requests.count == 1)
            #expect(harness.integration.webViewSnapshotter.isAwaitingAnswer)
            await drainReplayQueue()
            #expect(try uploadsNoRed(harness))

            harness.webKit.completions[0](nil)
            #expect(!harness.integration.webViewSnapshotter.isAwaitingAnswer)
            #expect(capture(harness))
            #expect(harness.webKit.requests.count == 2)
            await drainReplayQueue()

            let screenshot = try #require(harness.snapshots.screenshots.last)
            #expect(try isRed(uploadedCenter(screenshot)))
        }

        @Test("asks WebKit again once the web view whose answer it awaited is gone")
        func asksAgainOnceWebViewIsGone() async throws {
            let harness = try makeHarness()
            defer { close(harness) }
            let root = try #require(harness.window.rootViewController?.view)
            let released = AsyncLatch()

            weak var gone: WKWebView?
            autoreleasepool {
                let temporary = ReleasedWebView(frame: bounds)
                temporary.isOpaque = true
                temporary.onRelease = released.signal
                root.addSubview(temporary)
                gone = temporary
                _ = capture(harness)
                temporary.removeFromSuperview()
            }
            #expect(harness.webKit.requests.count == 1)
            await released.wait()
            try #require(gone == nil)
            #expect(!harness.integration.webViewSnapshotter.isAwaitingAnswer)

            harness.webKit.reply = .during(redImage())
            #expect(capture(harness))
            #expect(harness.webKit.requests.count == 2)
            #expect(harness.webKit.requests.last == ObjectIdentifier(harness.webView))
            await drainReplayQueue()

            let screenshot = try #require(harness.snapshots.screenshots.last)
            #expect(try isRed(uploadedCenter(screenshot)))
        }

        @Test("asks WebKit nothing once recording has stopped")
        func stoppedRecording() throws {
            let harness = try makeHarness()
            defer { close(harness) }
            harness.webKit.reply = .during(redImage())
            harness.sdk.stopSessionRecording()

            #expect(!capture(harness))
            #expect(harness.webKit.requests.isEmpty)
        }

        @Test("draws the window as before when web view snapshots are off")
        func optionOff() async throws {
            let harness = try makeHarness(webViewSnapshots: false)
            defer { close(harness) }
            harness.webKit.reply = .during(redImage())

            _ = capture(harness)
            #expect(harness.webKit.requests.isEmpty)
            await drainReplayQueue()
            #expect(try uploadsNoRed(harness))
        }

        @Test("draws the window as before when a native view lies over the web view")
        func nativeOverlay() async throws {
            let harness = try makeHarness()
            defer { close(harness) }
            harness.webKit.reply = .during(redImage())
            harness.window.rootViewController?.view.addSubview(UILabel(frame: CGRect(x: 20, y: 60, width: 120, height: 40)))

            _ = capture(harness)
            #expect(harness.webKit.requests.isEmpty)
            await drainReplayQueue()
            #expect(try uploadsNoRed(harness))
        }

        @Test("draws a bridge episode's first frame as before")
        func episodeFirstFrame() async throws {
            let harness = try makeHarness()
            defer { close(harness) }
            harness.webKit.reply = .during(redImage())

            _ = capture(harness, episodeFirstFrame: true)
            #expect(harness.webKit.requests.isEmpty)
            await drainReplayQueue()
            #expect(try uploadsNoRed(harness))
        }
    }
#endif
