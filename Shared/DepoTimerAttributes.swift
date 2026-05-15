import Foundation

#if canImport(ActivityKit)
import ActivityKit

/// Live Activity attributes shared between the iOS app and the widget extension.
/// `ContentState` is the dynamic portion that's updated as the depo timer runs.
public struct DepoTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Start of the currently running session (the most recent "In" punch).
        public var sessionStart: Date
        /// Sum of all completed sessions before the current one, in seconds.
        public var priorCompletedSeconds: Double

        public init(sessionStart: Date, priorCompletedSeconds: Double) {
            self.sessionStart = sessionStart
            self.priorCompletedSeconds = priorCompletedSeconds
        }
    }

    public init() {}
}
#endif
