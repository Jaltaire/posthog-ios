#if os(iOS)
    import Foundation

    final class PostHogReplayCaptureTimer {
        typealias Start = (TimeInterval, @escaping () -> Void) -> () -> Void

        private let lock = NSLock()
        private let start: Start
        private var cancel: (() -> Void)?

        init(start: @escaping Start = PostHogReplayCaptureTimer.mainQueueTimer) {
            self.start = start
        }

        var isRunning: Bool {
            lock.withLock { cancel != nil }
        }

        func begin(every interval: TimeInterval, _ action: @escaping () -> Void) {
            end()
            guard interval > 0 else {
                return
            }
            let cancel = start(interval, action)
            lock.withLock { self.cancel = cancel }
        }

        func end() {
            let cancel = lock.withLock { () -> (() -> Void)? in
                defer { self.cancel = nil }
                return self.cancel
            }
            cancel?()
        }

        static func mainQueueTimer(_ interval: TimeInterval, _ action: @escaping () -> Void) -> () -> Void {
            let timer = DispatchSource.makeTimerSource(queue: .main)
            timer.schedule(deadline: .now() + interval, repeating: interval)
            timer.setEventHandler(handler: action)
            timer.resume()
            return { timer.cancel() }
        }
    }
#endif
