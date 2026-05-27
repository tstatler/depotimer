import Foundation
import Combine
import DepoCore

#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#elseif os(iOS)
import UIKit
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

    public var isClockedIn: Bool { entries.first?.type == .in }
    public var completedMs: TimeInterval { DepoMath.completedSeconds(entries) }
    public var totalMs: TimeInterval { DepoMath.totalSeconds(entries) }

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

    // MARK: - Export

    public func buildTextData() -> String { DepoExport.text(from: entries) }
    public func buildCSVData() -> String { DepoExport.csv(from: entries) }

    public func defaultCSVFilename() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return "time-log-\(f.string(from: Date())).csv"
    }

    /// Writes a temp CSV file and returns its URL. Used by the iOS share sheet.
    public func writeTempCSV() -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(defaultCSVFilename())
        do {
            try buildCSVData().write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    @discardableResult
    public func copyToClipboard() -> Bool {
        let text = buildTextData()
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #elseif os(iOS)
        UIPasteboard.general.string = text
        #endif
        return true
    }

    #if os(macOS)
    public func saveCSVFile() {
        DispatchQueue.main.async {
            let panel = NSSavePanel()
            panel.nameFieldStringValue = self.defaultCSVFilename()
            panel.allowedContentTypes = [.commaSeparatedText]
            panel.isExtensionHidden = false
            panel.canCreateDirectories = true
            panel.title = "Save Time Log"
            let response = panel.runModal()
            guard response == .OK, let url = panel.url else { return }
            try? self.buildCSVData().write(to: url, atomically: true, encoding: .utf8)
        }
    }
    #endif

    // MARK: - Formatting (kept for view compatibility)

    public func formatSeconds(_ totalSec: Int) -> String { DepoFormat.seconds(totalSec) }
    public func formatTime(_ date: Date) -> String { DepoFormat.time(date) }
}
