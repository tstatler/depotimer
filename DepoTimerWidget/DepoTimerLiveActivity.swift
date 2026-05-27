import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit
import DepoLiveActivity

struct DepoTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DepoTimerAttributes.self) { context in
            // Lock screen / banner UI
            LockScreenView(state: context.state)
                .activityBackgroundTint(Color(red: 0.961, green: 0.961, blue: 0.949))
                .activitySystemActionForegroundColor(.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "record.circle.fill")
                        .foregroundStyle(Color(red: 0.847, green: 0.353, blue: 0.188))
                        .font(.title2)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Button(intent: StopDepoIntent()) {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .tint(Color(red: 0.847, green: 0.353, blue: 0.188))
                    .buttonStyle(.borderedProminent)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text("On the record")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                        ElapsedTimerText(state: context.state)
                            .font(.title2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Color(red: 0.094, green: 0.373, blue: 0.647))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) { EmptyView() }
            } compactLeading: {
                Image(systemName: "record.circle.fill")
                    .foregroundStyle(Color(red: 0.847, green: 0.353, blue: 0.188))
            } compactTrailing: {
                ElapsedTimerText(state: context.state)
                    .font(.caption.monospacedDigit())
            } minimal: {
                Image(systemName: "record.circle.fill")
                    .foregroundStyle(Color(red: 0.847, green: 0.353, blue: 0.188))
            }
        }
    }
}

private struct LockScreenView: View {
    let state: DepoTimerAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "record.circle.fill")
                .font(.title)
                .foregroundStyle(Color(red: 0.847, green: 0.353, blue: 0.188))

            VStack(alignment: .leading, spacing: 2) {
                Text("Depo on the record")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                ElapsedTimerText(state: state)
                    .font(.title2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color(red: 0.094, green: 0.373, blue: 0.647))
            }

            Spacer()

            Button(intent: StopDepoIntent()) {
                Label("Stop", systemImage: "stop.fill")
                    .labelStyle(.titleAndIcon)
            }
            .tint(Color(red: 0.847, green: 0.353, blue: 0.188))
            .buttonStyle(.borderedProminent)
        }
        .padding(14)
    }
}

/// Auto-updating elapsed time = priorCompletedSeconds + (now - sessionStart).
/// `Text(timerInterval:)` ticks on its own without the widget receiving updates.
private struct ElapsedTimerText: View {
    let state: DepoTimerAttributes.ContentState

    var body: some View {
        // Shift the timer's "start" earlier by priorCompletedSeconds so the running
        // total includes earlier sessions.
        let virtualStart = state.sessionStart.addingTimeInterval(-state.priorCompletedSeconds)
        return Text(timerInterval: virtualStart...Date.distantFuture,
                    pauseTime: nil,
                    countsDown: false,
                    showsHours: true)
    }
}
