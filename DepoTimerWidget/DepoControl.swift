import AppIntents
import SwiftUI
import WidgetKit
import DepoCore
import DepoLiveActivity

/// Single-tap Start/Stop toggle that lives in Control Center, the lock screen, or the Action Button.
struct DepoControl: ControlWidget {
    static let kind: String = "net.eurekastreet.DepoTimer.DepoControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { isRunning in
            ControlWidgetToggle(
                "Depo Timer",
                isOn: isRunning,
                action: TogglePunchIntent(),
                valueLabel: { running in
                    Label(running ? "On the record" : "Off the record",
                          systemImage: running ? "record.circle.fill" : "record.circle")
                }
            )
        }
        .displayName("Depo Timer")
        .description("Start or stop the depo recording timer.")
    }
}

extension DepoControl {
    struct Provider: ControlValueProvider {
        var previewValue: Bool { false }
        func currentValue() async throws -> Bool {
            DepoStorage.isRunning
        }
    }
}
