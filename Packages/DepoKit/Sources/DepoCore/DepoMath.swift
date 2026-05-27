import Foundation

public enum DepoMath {
    /// Sum of fully-paired sessions (excludes any open session).
    public static func completedSeconds(_ entries: [DepoEntry]) -> TimeInterval {
        var total: TimeInterval = 0
        for i in 0..<entries.count {
            let e = entries[i]
            if e.type == .out, i + 1 < entries.count, entries[i + 1].type == .in {
                total += e.time.timeIntervalSince(entries[i + 1].time)
            }
        }
        return total
    }

    /// Total including the live open session (if any).
    public static func totalSeconds(_ entries: [DepoEntry], now: Date = Date()) -> TimeInterval {
        var t = completedSeconds(entries)
        if entries.first?.type == .in, let start = entries.first?.time {
            t += now.timeIntervalSince(start)
        }
        return t
    }
}
