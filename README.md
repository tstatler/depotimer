# MenuBarTimer 🍅

A native macOS Pomodoro timer that lives in your menu bar. Built with Swift + SwiftUI.

## Features

- ⏱ **Three modes**: Focus (25 min), Short Break (5 min), Long Break (15 min)
- 📊 **Circular progress ring** with animated countdown
- 🔔 **macOS notifications** when each session ends
- 🍎 **Menubar icon** shows the current countdown
- 🎨 **Color-coded modes** — red for focus, green/blue for breaks
- No dock icon (pure menu bar app)

## How to Open in Xcode

1. Open **Xcode** (requires Xcode 15+ and macOS 13+)
2. Open the folder: **File → Open** → select the `MenuBarTimer` folder
3. Select the `MenuBarTimer.xcodeproj` file
4. **Important**: In the project settings, change `PRODUCT_BUNDLE_IDENTIFIER` from  
   `com.yourname.MenuBarTimer` to something unique (e.g. `com.johndoe.MenuBarTimer`)
5. Set your **Team** under Signing & Capabilities (use your Apple ID)
6. Press **⌘R** to build and run

## Project Structure

```
MenuBarTimer/
├── MenuBarTimerApp.swift   # App entry point + AppDelegate (status bar setup)
├── TimerModel.swift        # Timer logic, Pomodoro modes, notifications
├── TimerView.swift         # SwiftUI popover UI
├── Info.plist              # App configuration (LSUIElement hides dock icon)
└── MenuBarTimer.entitlements
```

## Customizing Durations

In `TimerModel.swift`, edit the `duration` computed property in `TimerMode`:

```swift
var duration: TimeInterval {
    switch self {
    case .focus:      return 25 * 60  // ← change to e.g. 50 * 60
    case .shortBreak: return 5 * 60   // ← change to e.g. 10 * 60
    case .longBreak:  return 15 * 60  // ← change to e.g. 20 * 60
    }
}
```

## Notifications

The app uses `UserNotifications`. On first launch, macOS will ask for permission to send notifications. Grant it to receive end-of-session alerts.

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15+
