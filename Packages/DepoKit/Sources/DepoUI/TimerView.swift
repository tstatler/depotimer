import SwiftUI
import DepoCore

// MARK: - Color palette (matches HTML)
private extension Color {
    static let depoGreen = Color(red: 0.114, green: 0.620, blue: 0.459)  // #1D9E75
    static let depoRed   = Color(red: 0.847, green: 0.353, blue: 0.188)  // #D85A30
    static let depoBlue  = Color(red: 0.094, green: 0.373, blue: 0.647)  // #185FA5
    static let surfaceBg = Color(red: 0.961, green: 0.961, blue: 0.949)  // #f5f5f3
    static let mutedText = Color(red: 0.533, green: 0.529, blue: 0.502)  // #888780
    static let border    = Color.black.opacity(0.12)

    static var cardBg: Color {
        #if os(macOS)
        Color(NSColor.windowBackgroundColor)
        #else
        Color(UIColor.systemBackground)
        #endif
    }
}

// MARK: - Root view
public struct TimerView: View {
    @ObservedObject var model: TimerModel
    @State private var pendingExport: ExportAction?
    @State private var csvShareURL: URL?

    private enum ExportAction { case copy, csv }

    public init(model: TimerModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            if !model.entries.isEmpty {
                TotalCard(model: model)
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .padding(.bottom, 8)
            }

            LogCard(model: model,
                    onCopy: { requestExport(.copy) },
                    onCSV: { requestExport(.csv) })
                .padding(.horizontal, 14)
                .padding(.top, model.entries.isEmpty ? 14 : 0)

            Spacer(minLength: 0)

            DepoButton(model: model)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    Color.surfaceBg
                        .shadow(color: .black.opacity(0.06), radius: 4, y: -2)
                )
        }
        #if os(macOS)
        .frame(width: 300)
        #endif
        .background(Color.surfaceBg)
        .confirmationDialog(
            "Timer is still running",
            isPresented: Binding(
                get: { pendingExport != nil && model.isClockedIn },
                set: { if !$0 { pendingExport = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Stop & Export") {
                model.punch()
                performPendingExport()
            }
            Button("Export As-Is") { performPendingExport() }
            Button("Cancel", role: .cancel) { pendingExport = nil }
        } message: {
            Text("Stop the timer before exporting, or export the log as-is?")
        }
        #if os(iOS)
        .sheet(item: $csvShareURL) { url in
            ShareSheet(items: [url])
        }
        #endif
    }

    private func requestExport(_ action: ExportAction) {
        if model.isClockedIn {
            pendingExport = action
        } else {
            pendingExport = action
            performPendingExport()
        }
    }

    private func performPendingExport() {
        guard let action = pendingExport else { return }
        switch action {
        case .copy:
            model.copyToClipboard()
        case .csv:
            #if os(macOS)
            model.saveCSVFile()
            #elseif os(iOS)
            csvShareURL = model.writeTempCSV()
            #endif
        }
        pendingExport = nil
    }
}

// Make URL Identifiable for `.sheet(item:)`
#if os(iOS)
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - Total time card
struct TotalCard: View {
    @ObservedObject var model: TimerModel
    @State private var pulseOpacity: Double = 1.0

    var body: some View {
        HStack {
            HStack(spacing: 5) {
                Text("Total time")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.mutedText)
                    .textCase(.uppercase)
                    .tracking(0.5)

                if model.isClockedIn {
                    Circle()
                        .fill(Color.depoGreen)
                        .frame(width: 7, height: 7)
                        .opacity(pulseOpacity)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                                   value: pulseOpacity)
                        .onAppear { pulseOpacity = 0.3 }
                }
            }
            Spacer()
            Text(model.formatSeconds(model.liveTotalSeconds))
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.depoBlue)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.border, lineWidth: 0.5))
    }
}

// MARK: - Log card
struct LogCard: View {
    @ObservedObject var model: TimerModel
    let onCopy: () -> Void
    let onCSV: () -> Void

    @State private var copyConfirmed = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text("Log")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.mutedText)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
                if !model.entries.isEmpty {
                    Button(action: {
                        onCopy()
                        copyConfirmed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copyConfirmed = false
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: copyConfirmed ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 10, weight: .medium))
                            Text(copyConfirmed ? "Copied" : "Copy")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(copyConfirmed ? .depoGreen : Color.mutedText.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: copyConfirmed)

                    Button(action: onCSV) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 10, weight: .medium))
                            Text("CSV")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(Color.mutedText.opacity(0.8))
                    }
                    .buttonStyle(.plain)

                    Rectangle()
                        .fill(Color.border)
                        .frame(width: 0.5, height: 12)

                    Button(action: model.clearAll) {
                        Image(systemName: "trash")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.mutedText.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)

            Divider().padding(.horizontal, 0)

            if model.entries.isEmpty {
                Text("No entries yet")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.706, green: 0.698, blue: 0.663))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(model.entries.enumerated()), id: \.element.id) { idx, entry in
                            EntryRow(entry: entry, model: model)

                            if entry.type == .out,
                               idx + 1 < model.entries.count,
                               model.entries[idx + 1].type == .in {
                                let dur = model.sessionDuration(
                                    outEntry: entry,
                                    inEntry: model.entries[idx + 1]
                                )
                                HStack {
                                    Spacer()
                                    Text(dur)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.depoBlue)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 2)
                                        .background(Color(red: 0.902, green: 0.945, blue: 0.984))
                                        .clipShape(Capsule())
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                #if os(macOS)
                .frame(maxHeight: 240)
                #endif
            }
        }
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.border, lineWidth: 0.5))
    }
}

// MARK: - Entry row with inline time editing
struct EntryRow: View {
    let entry: DepoEntry
    @ObservedObject var model: TimerModel

    @State private var isEditing = false
    @State private var editText = ""

    var isIn: Bool { entry.type == .in }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Circle()
                    .fill(isIn ? Color.depoGreen : Color.depoRed)
                    .frame(width: 9, height: 9)

                if isEditing {
                    TextField("HH:MM:SS", text: $editText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .medium))
                        .onSubmit(commitEdit)
                        .frame(width: 100)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(red: 0.945, green: 0.937, blue: 0.910))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.border))

                    Button(action: commitEdit) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.depoGreen)
                    }
                    .buttonStyle(.plain)

                    Button(action: { isEditing = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.depoRed)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(model.formatTime(entry.time))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .onTapGesture { startEdit() }
                }

                Spacer()

                Text(isIn ? "In" : "Out")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isIn ? Color(red: 0.059, green: 0.431, blue: 0.337) : Color(red: 0.6, green: 0.235, blue: 0.114))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(isIn ? Color(red: 0.882, green: 0.961, blue: 0.933) : Color(red: 0.980, green: 0.925, blue: 0.906))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)

            Divider().padding(.leading, 12)
        }
    }

    private func startEdit() {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        editText = f.string(from: entry.time)
        isEditing = true
    }

    private func commitEdit() {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        if let parsed = f.date(from: editText) {
            let cal = Calendar.current
            let originalComponents = cal.dateComponents([.year, .month, .day], from: entry.time)
            let timeComponents = cal.dateComponents([.hour, .minute, .second], from: parsed)
            var merged = DateComponents()
            merged.year = originalComponents.year
            merged.month = originalComponents.month
            merged.day = originalComponents.day
            merged.hour = timeComponents.hour
            merged.minute = timeComponents.minute
            merged.second = timeComponents.second
            if let newDate = cal.date(from: merged) {
                model.updateEntry(entry, newTime: newDate)
            }
        }
        isEditing = false
    }
}

// MARK: - Depo action button
struct DepoButton: View {
    @ObservedObject var model: TimerModel
    @State private var isPressed = false

    var body: some View {
        Button(action: model.punch) {
            Text(model.isClockedIn ? "Stop / Out" : "Start / In")
                .font(.system(size: 16, weight: .medium))
                .tracking(0.3)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(model.isClockedIn ? Color.depoRed : Color.depoGreen)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .opacity(isPressed ? 0.85 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}
