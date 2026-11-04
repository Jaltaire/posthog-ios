---
"posthog-ios": minor
---

Add the experimental `sessionReplayConfig.screenshotModeWebViewSnapshot` option. When a window shows nothing but one opaque web view, screenshot replay captures it with `WKWebView.takeSnapshot` instead of drawing the window's view hierarchy on the main thread.
