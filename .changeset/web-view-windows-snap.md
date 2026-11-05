---
"posthog-ios": minor
---

Add the experimental `sessionReplayConfig.screenshotModeWebViewSnapshot` option. When a window shows nothing but one opaque web view, screenshot replay captures it with `WKWebView.takeSnapshot` instead of drawing the window's view hierarchy, and draws the window as before whenever WebKit cannot answer during the capture.
