import Foundation
import Combine

#if canImport(AppKit)
import AppKit
import UniformTypeIdentifiers
#endif

public final class TimerModel: ObservableObject {
    @Published public var entries: [DepoEntry] = []
    @Published public var displayTitle: String = "Depo"
    @Published public var liveTotalSeconds: Int = 0

    private var tickTimer: AnyCancellable?
    private var cloudObserver: NSObjectProtocol?

    public init() {
        entries = DepoStorage.loadEntries()
        liveTotalSeconds = Int(totalMs)
        restartTickerIfNeeded()
        observeCloud()
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    deinit {
        if let obs = cloudObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    // MARK: - Computed

    public var isClockedIn: Bool {
        entries.first?.type == .in
    }

    public var completedMs: TimeInterval {
        DepoMath.completedSeconds(entries)
    }

    public var totalMs: TimeInterval {
        DepoMath.totalSeconds(entries)
    }

    public func sessionDuration(outEntry: DepoEntry, inEntry: DepoEntry) -> String {
        DepoExport.sessionDuration(outEntry: outEntry, inEntry: inEntry)
    }

    // MARK: - Actions

    public func punch() {
        let newType: DepoType = isClockedIn ? .out : .in
        entries.insert(DepoEntry(type: newType, time: Date()), at: 0)
        save()
        restartTickerIfNeeded()
        updateDisplayTitle()
    }

    public func clearAll() {
        entries.removeAll()
        stopTicker()
        liveTotalSeconds = 0
        displayTitle = "Depo"
        save()
    }

    public func updateEntry(_ entry: DepoEntry, newTime: Date) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[idx].time = newTime
            save()
            restartTickerIfNeeded()
            updateDisplayTitle()
        }
    }

    // MARK: - Ticker

    public func restartTickerIfNeeded() {
        stopTicker()
        liveTotalSeconds = Int(totalMs)
        guard isClockedIn else { return }
        tickTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.liveTotalSeconds = Int(self.totalMs)
                self.updateDisplayTitle()
            }
    }

    private func stopTicker() {
        tickTimer?.cancel()
        tickTimer = nil
    }

    private func updateDisplayTitle() {
        if isClockedIn {
            displayTitle = "● \(DepoFormat.seconds(liveTotalSeconds))"
        } else if totalMs > 0 {
            displayTitle = DepoFormat.seconds(Int(totalMs))
        } else {
            displayTitle = "Depo"
        }
    }

    // MARK: - Persistence & sync

    private func save() {
        DepoStorage.saveEntries(entries)
    }

    /// Re-read from the shared store and update UI if the data changed.
    /// Called both when iCloud notifies of an external change AND when the widget
    /// changes state (e.g. user tapped Control Center toggle while the app was running).
    public func refreshFromSharedStore() {
        let loaded = DepoStorage.loadEntries()
        guard loaded != entries else { return }
        entries = loaded
        restartTickerIfNeeded()
        updateDisplayTitle()
    }

    private func observeCloud() {
        cloudObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            self?.refreshFromSharedStore()
        }
    }

    // MARK: - Export (UI-agnostic)

    public func buildTextData() -> String { DepoExport.text(from: entries) }
    public func buildCSVData() -> String { DepoExport.csv(from: entries) }

    // MARK: - Mac-specific export helpers

    #if os(macOS)
    @discardableResult
    public func copyToClipboard() -> Bool {
        guard confirmExportIfRunning() else { return false }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(buildTextData(), forType: .string)
        return true
    }

    public func saveCSVFile() {
        guard confirmExportIfRunning() else { return }
        DispatchQueue.main.async {
            let panel = NSSavePanel()
            let dateSuffix = DateFormatter()
            dateSuffix.dateFormat = "yyyy-MM-dd"
            panel.nameFieldStringValue = "time-log-\(dateSuffix.string(from: Date())).csv"
            panel.allowedContentTypes = [.commaSeparatedText]
            panel.isExtensionHidden = false
            panel.canCreateDirectories = true
            panel.title = "Save Time Log"
            let response = panel.runModal()
            guard response == .OK, let url = panel.url else { return }
            try? self.buildCSVData().write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func confirmExportIfRunning() -> Bool {
        guard isClockedIn else { return true }
        let alert = NSAlert()
        alert.messageText = "Timer is still running"
        alert.informativeText = "Stop the timer before exporting, or export the log as-is?"
        alert.addButton(withTitle: "Stop & Export")
        alert.addButton(withTitle: "Export As-Is")
        alert.addButton(withTitle: "Cancel")
        switch alert.runModal() {
        case .alertFirstButtonReturn: punch(); return true
        case .alertSecondButtonReturn: return true
        default: return false
        }
    }
    #endif

    // MARK: - Formatting (kept for view compatibility)

    public func formatSeconds(_ totalSec: Int) -> String { DepoFormat.seconds(totalSec) }
    public func formatTime(_ date: Date) -> String { DepoFormat.time(date) }
}
