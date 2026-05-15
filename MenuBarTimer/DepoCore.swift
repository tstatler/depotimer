import Foundation

// MARK: - Entry types

public struct DepoEntry: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var type: DepoType
    public var time: Date

    public init(id: UUID = UUID(), type: DepoType, time: Date) {
        self.id = id
        self.type = type
        self.time = time
    }
}

public enum DepoType: String, Codable, Sendable {
    case `in`, out
}

// MARK: - Shared storage

/// Reads and writes the depo log to the App Group store and mirrors to iCloud key-value storage.
/// The widget extension and both apps (iOS + macOS) share the same backing data through this type.
public enum DepoStorage {
    /// Update this if you change the App Group identifier in entitlements.
    public static let appGroup = "group.com.yourname.depotimer"

    /// Storage key — preserved from earlier versions so existing local logs survive.
    public static let entriesKey = "punchEntries"

    public static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    public static func loadEntries() -> [DepoEntry] {
        // Prefer the App Group store.
        if let data = sharedDefaults.data(forKey: entriesKey),
           let saved = try? JSONDecoder().decode([DepoEntry].self, from: data) {
            return saved
        }
        // One-time migration from the pre-App-Group standard defaults.
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let saved = try? JSONDecoder().decode([DepoEntry].self, from: data) {
            saveEntries(saved)
            return saved
        }
        // One-time pull from iCloud on first launch on a fresh device.
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: entriesKey),
           let saved = try? JSONDecoder().decode([DepoEntry].self, from: data) {
            sharedDefaults.set(data, forKey: entriesKey)
            return saved
        }
        return []
    }

    public static func saveEntries(_ entries: [DepoEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        sharedDefaults.set(data, forKey: entriesKey)
        NSUbiquitousKeyValueStore.default.set(data, forKey: entriesKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    /// Inserts a new In or Out entry at the current moment, toggling the running state.
    /// Returns the new "is running" state so intents can report it.
    @discardableResult
    public static func togglePunch() -> Bool {
        var entries = loadEntries()
        let wasRunning = entries.first?.type == .in
        let newType: DepoType = wasRunning ? .out : .in
        entries.insert(DepoEntry(type: newType, time: Date()), at: 0)
        saveEntries(entries)
        return !wasRunning
    }

    public static var isRunning: Bool {
        loadEntries().first?.type == .in
    }

    /// When did the current in-progress session start? Nil when not clocked in.
    public static var currentSessionStart: Date? {
        let entries = loadEntries()
        return entries.first?.type == .in ? entries.first?.time : nil
    }
}

// MARK: - Computations

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

// MARK: - Formatting

public enum DepoFormat {
    public static func seconds(_ totalSec: Int) -> String {
        let h = totalSec / 3600
        let m = (totalSec % 3600) / 60
        let s = totalSec % 60
        if h > 0 { return "\(h)h \(m)m \(s)s" }
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }

    public static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm:ss a"
        return f.string(from: date)
    }
}

// MARK: - Exports

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
