#if os(iOS)
import Foundation
import ActivityKit
import DepoCore

/// Starts, updates, and ends the depo timer Live Activity based on shared-storage state.
/// Callable from the iOS app target and the widget extension target.
public enum DepoLiveActivityManager {

    /// Brings the Live Activity into sync with whatever's in shared storage.
    /// - If the timer is running and no activity exists: starts one.
    /// - If the timer is running and an activity exists: updates it.
    /// - If the timer is stopped: ends all activities.
    public static func sync() async {
        let entries = DepoStorage.loadEntries()
        let isRunning = entries.first?.type == .in
        let priorCompleted = DepoMath.completedSeconds(entries)

        if isRunning, let sessionStart = entries.first?.time {
            let state = DepoTimerAttributes.ContentState(
                sessionStart: sessionStart,
                priorCompletedSeconds: priorCompleted
            )
            let content = ActivityContent(state: state, staleDate: nil)

            if let current = Activity<DepoTimerAttributes>.activities.first {
                await current.update(content)
            } else {
                do {
                    _ = try Activity<DepoTimerAttributes>.request(
                        attributes: DepoTimerAttributes(),
                        content: content,
                        pushType: nil
                    )
                } catch {
                    // The user may have disabled Live Activities for the app.
                }
            }
        } else {
            for activity in Activity<DepoTimerAttributes>.activities {
                await activity.end(activity.content, dismissalPolicy: .immediate)
            }
        }
    }
}
#endif
