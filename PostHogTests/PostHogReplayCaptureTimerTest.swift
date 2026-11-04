#if os(iOS)
    import Foundation
    @testable import PostHog
    import Testing

    @Suite("Replay capture timer")
    struct PostHogReplayCaptureTimerTests {
        final class Recorder {
            var intervals: [TimeInterval] = []
            var actions: [() -> Void] = []
            var cancellations = 0

            func timer() -> PostHogReplayCaptureTimer {
                PostHogReplayCaptureTimer { interval, action in
                    self.intervals.append(interval)
                    self.actions.append(action)
                    return { self.cancellations += 1 }
                }
            }
        }

        @Test("starts a timer on a positive interval")
        func positiveInterval() {
            let recorder = Recorder()
            let timer = recorder.timer()
            timer.begin(every: 1) {}
            #expect(recorder.intervals == [1])
            #expect(timer.isRunning)
        }

        @Test("starts nothing on an interval of zero")
        func zeroInterval() {
            let recorder = Recorder()
            let timer = recorder.timer()
            timer.begin(every: 0) {}
            #expect(recorder.intervals.isEmpty)
            #expect(!timer.isRunning)
        }

        @Test("starts nothing on a negative interval")
        func negativeInterval() {
            let recorder = Recorder()
            let timer = recorder.timer()
            timer.begin(every: -1) {}
            #expect(recorder.intervals.isEmpty)
            #expect(!timer.isRunning)
        }

        @Test("runs the given action when the timer fires")
        func firesAction() {
            let recorder = Recorder()
            let timer = recorder.timer()
            var captures = 0
            timer.begin(every: 1) { captures += 1 }
            recorder.actions[0]()
            recorder.actions[0]()
            #expect(captures == 2)
        }

        @Test("cancels the timer when it ends")
        func endCancels() {
            let recorder = Recorder()
            let timer = recorder.timer()
            timer.begin(every: 1) {}
            timer.end()
            #expect(recorder.cancellations == 1)
            #expect(!timer.isRunning)
        }

        @Test("cancels nothing when it ends without having begun")
        func endWithoutBegin() {
            let recorder = Recorder()
            let timer = recorder.timer()
            timer.end()
            #expect(recorder.cancellations == 0)
            #expect(!timer.isRunning)
        }

        @Test("cancels nothing when it ends twice")
        func endTwice() {
            let recorder = Recorder()
            let timer = recorder.timer()
            timer.begin(every: 1) {}
            timer.end()
            timer.end()
            #expect(recorder.cancellations == 1)
        }

        @Test("replaces a running timer when it begins again")
        func beginReplaces() {
            let recorder = Recorder()
            let timer = recorder.timer()
            timer.begin(every: 1) {}
            timer.begin(every: 2) {}
            #expect(recorder.intervals == [1, 2])
            #expect(recorder.cancellations == 1)
            #expect(timer.isRunning)
        }

        @Test("stops a running timer when it begins again with no interval")
        func beginWithoutIntervalStops() {
            let recorder = Recorder()
            let timer = recorder.timer()
            timer.begin(every: 1) {}
            timer.begin(every: 0) {}
            #expect(recorder.cancellations == 1)
            #expect(!timer.isRunning)
        }

        @Test("fires on the main queue", .timeLimit(.minutes(1)))
        func mainQueueTimer() async {
            var cancel: (() -> Void)?
            let onMainThread: Bool = await withCheckedContinuation { continuation in
                var resumed = false
                cancel = PostHogReplayCaptureTimer.mainQueueTimer(0.01) {
                    guard !resumed else {
                        return
                    }
                    resumed = true
                    continuation.resume(returning: Thread.isMainThread)
                }
            }
            cancel?()
            #expect(onMainThread)
        }
    }

    @Suite("Replay capture interval", .serialized)
    class PostHogReplayCaptureIntervalTests {
        let server: MockPostHogServer

        init() {
            server = MockPostHogServer()
            server.start()
        }

        deinit {
            server.stop()
        }

        private func getSut(captureInterval: TimeInterval) -> PostHogSDK {
            let config = PostHogConfig(projectToken: "test_project_token", host: "http://localhost:9001")
            config.sessionReplay = false
            config.sessionReplayConfig.screenshotMode = true
            config.sessionReplayConfig.captureInterval = captureInterval
            config.disableReachabilityForTesting = true
            config.disableQueueTimerForTesting = true
            config.disableFlushOnBackgroundForTesting = true
            return PostHogSDK.with(config)
        }

        @Test("is off by default")
        func offByDefault() {
            #expect(PostHogSessionReplayConfig().captureInterval == 0)
        }

        @Test("captures on the interval while recording, and stops with the recording")
        func capturesWhileRecording() {
            let sut = getSut(captureInterval: 1)
            sut.startSessionRecording()
            #expect(sut.getReplayIntegration()?.isCapturingOnInterval == true)
            sut.stopSessionRecording()
            #expect(sut.getReplayIntegration()?.isCapturingOnInterval != true)
            sut.reset()
        }

        @Test("captures on layout passes alone without an interval")
        func noIntervalWithoutConfiguration() {
            let sut = getSut(captureInterval: 0)
            sut.startSessionRecording()
            #expect(sut.getReplayIntegration() != nil)
            #expect(sut.getReplayIntegration()?.isCapturingOnInterval == false)
            sut.stopSessionRecording()
            sut.reset()
        }
    }
#endif
