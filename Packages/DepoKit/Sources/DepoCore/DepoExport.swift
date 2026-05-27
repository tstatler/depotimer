import Foundation

public enum DepoExport {
    public static func sessionDuration(outEntry: DepoEntry, inEntry: DepoEntry) -> String {
        let secs = Int(outEntry.time.timeIntervalSince(inEntry.time))
        return DepoFormat.seconds(secs)
    }

    /// Clipboard / plain-text representation. Oldest-first.
    public static func text(from entries: [DepoEntry]) -> String {
        guard !entries.isEmpty else { return "" }
        var lines: [String] = []
        for i in stride(from: entries.count - 1, through: 0, by: -1) {
            let e = entries[i]
            lines.append("\(DepoFormat.time(e.time))  (\(e.type == .in ? "In" : "Out"))")
            if e.type == .out, i + 1 < entries.count, entries[i + 1].type == .in {
                lines.append("  Duration: \(sessionDuration(outEntry: e, inEntry: entries[i + 1]))")
            }
        }
        lines.append("")
        lines.append("Total: \(DepoFormat.seconds(Int(DepoMath.totalSeconds(entries))))")
        return lines.joined(separator: "\n")
    }

    /// CSV download format. Oldest-first. Trailing `"Total"` row.
    public static func csv(from entries: [DepoEntry]) -> String {
        var rows = [#""Type","Time","Duration""#]
        for i in stride(from: entries.count - 1, through: 0, by: -1) {
            let e = entries[i]
            var dur = ""
            if e.type == .out, i + 1 < entries.count, entries[i + 1].type == .in {
                dur = sessionDuration(outEntry: e, inEntry: entries[i + 1])
            }
            rows.append(#""\#(e.type == .in ? "In" : "Out")","\#(DepoFormat.time(e.time))","\#(dur)""#)
        }
        if !entries.isEmpty {
            rows.append(#""Total","","\#(DepoFormat.seconds(Int(DepoMath.completedSeconds(entries))))""#)
        }
        return rows.joined(separator: "\n")
    }
}
