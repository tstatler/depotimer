import Foundation

/// Reads and writes the depo log to the App Group store and mirrors to iCloud key-value storage.
/// The widget extension and both apps (iOS + macOS) share the same backing data through this type.
public enum DepoStorage {
    /// Update this if you change the App Group identifier in entitlements.
    public static let appGroup = "group.net.eurekastreet.DepoTimer"

    /// Storage key — preserved from earlier versions so existing local logs survive.
    public static let entriesKey = "punchEntries"

    public static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    public static func loadEntries() -> [DepoEntry] {
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
