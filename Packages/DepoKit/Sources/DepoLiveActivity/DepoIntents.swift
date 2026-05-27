#if os(iOS)
import Foundation
import AppIntents
import WidgetKit
import DepoCore

/// Toggles the depo timer. Backs the Control Center widget and any in-app intent buttons.
public struct TogglePunchIntent: SetValueIntent, LiveActivityIntent {
    public static var title: LocalizedStringResource = "Toggle Depo Timer"
    public static var description = IntentDescription("Start or stop the depo recording timer.")

    @Parameter(title: "Running")
    public var value: Bool

    public init() {}
    public init(value: Bool) { self.value = value }

    public func perform() async throws -> some IntentResult {
        let wasRunning = DepoStorage.isRunning
        if value != wasRunning {
            DepoStorage.togglePunch()
        }
        await DepoLiveActivityManager.sync()
        ControlCenter.shared.reloadAllControls()
        return .result()
    }
}

/// Stops the depo timer. Used by the "Stop" button inside the Live Activity.
public struct StopDepoIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Stop Depo Timer"

    public init() {}

    public func perform() async throws -> some IntentResult {
        if DepoStorage.isRunning {
            DepoStorage.togglePunch()
        }
        await DepoLiveActivityManager.sync()
        ControlCenter.shared.reloadAllControls()
        return .result()
    }
}
#endif
