import SwiftUI
import SwiftData

struct LogTab: View {
    @Environment(\.modelContext) private var context
    @Query private var logs: [SleepLog]
    @EnvironmentObject var whoop: WhoopStore

    private let healthKit = HealthKitReader()

    @State private var inBedDate = defaultTime(hour: 23, minute: 45)
    @State private var lightsOutDate = defaultTime(hour: 23, minute: 45)
    @State private var latency: Int = 20
    @State private var wakeCount: Int = 2
    @State private var wakeMin: Int = 45
    @State private var finalWakeDate = defaultTime(hour: 5, minute: 45)
    @State private var outBedDate = defaultTime(hour: 5, minute: 45)
    @State private var quality: Double = 5
    @State private var mood: Double = 5
    @State private var saveFeedback = ""
    @State private var importStatus = ""
    @State private var importing = false

    // Whoop enrichment held on the form between import and save.
    @State private var whoopStrain: Double? = nil
    @State private var whoopRecovery: Int? = nil
    @State private var whoopHRV: Double? = nil
    @State private var whoopRHR: Int? = nil

    // Computed live metrics for the preview card (no @Model instance needed).
    private var previewTIB: Int {
        let inB = hhmmString(inBedDate).hhmmMinutes
        var out = hhmmString(outBedDate).hhmmMinutes
        if out <= inB { out += 1440 }
        return out - inB
    }
    private var previewTST: Int { max(0, previewTIB - latency - wakeMin) }
    private var previewSE: Int {
        guard previewTIB > 0 else { return 0 }
        return Int((Double(previewTST) / Double(previewTIB) * 100).rounded())
    }

    private var todaysLog: SleepLog? {
        logs.first(where: { $0.date == todayISO() })
    }

    var body: some View {
        #if os(iOS)
        iosBody
        #else
        macBody
        #endif
    }

    #if os(iOS)
    // iOS: Form for inputs (native cell treatment) + edge-to-edge visual cards for previews.
    private var iosBody: some View {
        Form {
            Section {
                Text("Fill this in each morning within 30 minutes of waking. Use estimates — do not check the clock at night.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            Section {
                importRowIOS
            }

            Section("Times") {
                formTimeRow("Got into bed", $inBedDate)
                formTimeRow("Lights out", $lightsOutDate)
                formTimeRow("Final wake-up", $finalWakeDate)
                formTimeRow("Out of bed", $outBedDate)
            }

            Section("Night details") {
                formNumberRow("Minutes to fall asleep", value: $latency, range: 0...300)
                formNumberRow("Times woke", value: $wakeCount, range: 0...20)
                formNumberRow("Minutes awake", value: $wakeMin, range: 0...500)
            }

            Section("Ratings") {
                formRatingRow("Sleep quality", value: $quality)
                formRatingRow("Morning mood", value: $mood)
            }

            // Edge-to-edge visual preview card — three big numbers.
            Section {
                previewCardIOS
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))

            if hasWhoopContext {
                Section {
                    whoopGridIOS
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
            }

            // Full-width save button.
            Section {
                Button(action: save) {
                    HStack {
                        Spacer()
                        if !saveFeedback.isEmpty {
                            Image(systemName: "checkmark")
                            Text(saveFeedback)
                        } else if todaysLog != nil {
                            Text("Update today's log")
                        } else {
                            Text("Save today's log")
                        }
                        Spacer()
                    }
                    .fontWeight(.semibold)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 24, trailing: 16))
            }
        }
        .onAppear(perform: loadExistingForToday)
    }
    #endif

    // Mac retains the original ScrollView + GroupBox layout — looks right on a window with room to breathe.
    private var macBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Fill this in each morning within 30 minutes of waking. Use estimates — do not check the clock at night.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                importRow

                GroupBox("Times") {
                    VStack(alignment: .leading, spacing: 10) {
                        timeRow("Got into bed", $inBedDate)
                        timeRow("Tried to sleep (lights out)", $lightsOutDate)
                        timeRow("Final wake-up", $finalWakeDate)
                        timeRow("Got out of bed", $outBedDate)
                    }
                    .padding(.vertical, 4)
                }

                GroupBox("Night details") {
                    VStack(alignment: .leading, spacing: 10) {
                        numberRow("Minutes to fall asleep", value: $latency, range: 0...300)
                        numberRow("Times woke during the night", value: $wakeCount, range: 0...20)
                        numberRow("Total minutes awake", value: $wakeMin, range: 0...500)
                    }
                    .padding(.vertical, 4)
                }

                GroupBox("Ratings") {
                    VStack(alignment: .leading, spacing: 14) {
                        ratingRow("Sleep quality", value: $quality)
                        ratingRow("Morning mood", value: $mood)
                    }
                    .padding(.vertical, 4)
                }

                previewCard

                whoopContextCard

                Button(action: save) {
                    HStack {
                        if !saveFeedback.isEmpty {
                            Image(systemName: "checkmark")
                            Text(saveFeedback)
                        } else if todaysLog != nil {
                            Text("Update today's log")
                        } else {
                            Text("Save today's log")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
            .onAppear(perform: loadExistingForToday)
        }
    }

    private var importRow: some View {
        HStack(spacing: 10) {
            Button(action: importLastNight) {
                HStack(spacing: 6) {
                    if importing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                    }
                    Text("Import last night")
                }
            }
            .disabled(importing)
            .help("Pulls sleep timing from Apple Watch (via HealthKit) and strain/recovery from Whoop. Either source alone is enough.")

            if !importStatus.isEmpty {
                Text(importStatus)
                    .font(.caption)
                    .foregroundStyle(importStatus.hasPrefix("Imported") ? .green : .red)
                    .lineLimit(2)
            } else if !healthKit.isAvailable && whoop.status != .connected {
                Text("No source available — connect Whoop in Settings (⌘,) or enable Apple Health.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
    }

    private func importLastNight() {
        importing = true
        importStatus = ""
        Task {
            async let hkDraft = fetchHealthKitDraft()
            async let whoopDraft = fetchWhoopDraft()
            let (hk, wh) = await (hkDraft, whoopDraft)

            guard let merged = mergeDrafts(healthKit: hk, whoop: wh) else {
                importStatus = "No recent sleep found from Apple Watch or Whoop."
                importing = false
                return
            }

            applyImported(merged)
            importStatus = "Imported sleep ending \(formatTime12h(merged.outBed)) on \(merged.date) (\(sourceLabel(hk: hk, wh: wh)))."
            importing = false
        }
    }

    private func fetchHealthKitDraft() async -> SleepLogDraft? {
        do { return try await healthKit.fetchLatestSleep() }
        catch { return nil }
    }

    private func fetchWhoopDraft() async -> SleepLogDraft? {
        guard whoop.status == .connected else { return nil }
        do { return try await whoop.importLatestSleep() }
        catch { return nil }
    }

    private func sourceLabel(hk: SleepLogDraft?, wh: SleepLogDraft?) -> String {
        switch (hk != nil, wh != nil) {
        case (true, true):   return "Apple Watch + Whoop"
        case (true, false):  return "Apple Watch"
        case (false, true):  return "Whoop"
        case (false, false): return "no source"
        }
    }

    /// Apple Watch (HealthKit) is preferred for sleep timing because it exposes
    /// explicit per-event wake samples and sleep latency. Whoop fills in strain
    /// and recovery (Whoop-only metrics) and serves as fallback when the strap
    /// was off / Watch wasn't worn.
    private func mergeDrafts(healthKit hk: SleepLogDraft?, whoop wh: SleepLogDraft?) -> SleepLogDraft? {
        guard let primary = hk ?? wh else { return nil }
        return SleepLogDraft(
            date: primary.date,
            inBed: primary.inBed,
            lightsOut: primary.lightsOut,
            latency: primary.latency,
            wakeCount: primary.wakeCount,
            wakeMin: primary.wakeMin,
            finalWake: primary.finalWake,
            outBed: primary.outBed,
            quality: primary.quality,
            mood: primary.mood,
            whoopStrain: wh?.whoopStrain,
            whoopRecovery: wh?.whoopRecovery,
            whoopHRV: hk?.whoopHRV ?? wh?.whoopHRV,
            whoopRHR: hk?.whoopRHR ?? wh?.whoopRHR
        )
    }

    private func applyImported(_ draft: SleepLogDraft) {
        inBedDate = parseHHMM(draft.inBed)
        lightsOutDate = parseHHMM(draft.lightsOut)
        finalWakeDate = parseHHMM(draft.finalWake)
        outBedDate = parseHHMM(draft.outBed)
        wakeCount = draft.wakeCount
        wakeMin = draft.wakeMin
        whoopStrain = draft.whoopStrain
        whoopRecovery = draft.whoopRecovery
        whoopHRV = draft.whoopHRV
        whoopRHR = draft.whoopRHR
        // Leave latency, quality, and mood for the user to fill — Whoop doesn't provide them.
    }

    private var hasWhoopContext: Bool {
        whoopStrain != nil || whoopRecovery != nil || whoopHRV != nil || whoopRHR != nil
    }

    #if os(iOS)
    // MARK: - iOS Form rows

    /// iOS version of the import button — single row inside a Form Section.
    private var importRowIOS: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: importLastNight) {
                HStack(spacing: 6) {
                    if importing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                    }
                    Text("Import last night")
                }
            }
            .disabled(importing)

            if !importStatus.isEmpty {
                Text(importStatus)
                    .font(.caption)
                    .foregroundStyle(importStatus.hasPrefix("Imported") ? .green : .red)
                    .lineLimit(3)
            } else if !healthKit.isAvailable && whoop.status != .connected {
                Text("Connect Whoop in Settings or enable Apple Health.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func formTimeRow(_ label: String, _ binding: Binding<Date>) -> some View {
        HStack {
            Text(label)
            Spacer()
            DatePicker("", selection: binding, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
    }

    private func formNumberRow(_ label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Stepper(value: value, in: range) {
            HStack {
                Text(label)
                Spacer()
                Text("\(value.wrappedValue)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formRatingRow(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: 1...10, step: 1)
        }
        .padding(.vertical, 2)
    }

    // 3-up preview card: big numbers, color on efficiency.
    private var previewCardIOS: some View {
        HStack(spacing: 8) {
            previewBox(label: "Time in bed", value: formatDurationMinutes(previewTIB))
            previewBox(label: "Est. sleep",  value: formatDurationMinutes(previewTST))
            let c = seColor(previewSE)
            previewBox(label: "Efficiency",  value: "\(previewSE)%", tint: Color(red: c.red, green: c.green, blue: c.blue))
        }
    }

    private func previewBox(label: String, value: String, tint: Color? = nil) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(tint ?? .primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // 2×2 grid of Whoop stats with color-coded values.
    private var whoopGridIOS: some View {
        let items = whoopGridItems()
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(items.indices, id: \.self) { i in
                whoopStatBox(items[i])
            }
        }
    }

    private struct WhoopGridItem {
        let label: String
        let value: String
        let tint: Color?
    }

    private func whoopGridItems() -> [WhoopGridItem] {
        var items: [WhoopGridItem] = []
        if let strain = whoopStrain {
            items.append(.init(label: "Strain (day)", value: String(format: "%.1f", strain), tint: strainColor(strain)))
        }
        if let rec = whoopRecovery {
            items.append(.init(label: "Recovery", value: "\(rec)%", tint: recoveryColor(rec)))
        }
        if let hrv = whoopHRV {
            items.append(.init(label: "HRV", value: "\(Int(hrv.rounded())) ms", tint: nil))
        }
        if let rhr = whoopRHR {
            items.append(.init(label: "Resting HR", value: "\(rhr) bpm", tint: nil))
        }
        return items
    }

    private func whoopStatBox(_ item: WhoopGridItem) -> some View {
        VStack(spacing: 4) {
            Text(item.value)
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(item.tint ?? .primary)
            Text(item.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    #endif

    // MARK: - Mac rows (existing — used in macBody only)

    private func timeRow(_ label: String, _ binding: Binding<Date>) -> some View {
        HStack {
            Text(label).font(.callout).frame(width: 220, alignment: .leading)
            DatePicker("", selection: binding, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .frame(width: 110)
            Spacer()
        }
    }

    private func numberRow(_ label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(label).font(.callout).frame(width: 220, alignment: .leading)
            Stepper(value: value, in: range) {
                Text("\(value.wrappedValue)").monospacedDigit().frame(width: 50, alignment: .trailing)
            }
            .labelsHidden()
            Spacer()
        }
    }

    private func ratingRow(_ label: String, value: Binding<Double>) -> some View {
        HStack {
            Text("\(label): \(Int(value.wrappedValue))")
                .font(.callout)
                .frame(width: 220, alignment: .leading)
                .monospacedDigit()
            Slider(value: value, in: 1...10, step: 1)
        }
    }

    @ViewBuilder
    private var whoopContextCard: some View {
        if whoopStrain != nil || whoopRecovery != nil || whoopHRV != nil || whoopRHR != nil {
            VStack(alignment: .leading, spacing: 8) {
                Text("Whoop context")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
                    .kerning(0.6)
                HStack(spacing: 12) {
                    if let strain = whoopStrain {
                        whoopStat("Strain (day)", String(format: "%.1f", strain), tint: strainColor(strain))
                    }
                    if let rec = whoopRecovery {
                        whoopStat("Recovery", "\(rec)%", tint: recoveryColor(rec))
                    }
                    if let hrv = whoopHRV {
                        whoopStat("HRV", "\(Int(hrv.rounded())) ms", tint: nil)
                    }
                    if let rhr = whoopRHR {
                        whoopStat("RHR", "\(rhr) bpm", tint: nil)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func whoopStat(_ label: String, _ value: String, tint: Color?) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(tint ?? .primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var previewCard: some View {
        HStack(spacing: 12) {
            previewStat(label: "Time in bed", value: formatDurationMinutes(previewTIB), tint: nil)
            previewStat(label: "Est. sleep", value: formatDurationMinutes(previewTST), tint: nil)
            let c = seColor(previewSE)
            previewStat(
                label: "Sleep efficiency",
                value: "\(previewSE)%",
                tint: Color(red: c.red, green: c.green, blue: c.blue)
            )
        }
        .padding(.vertical, 4)
    }

    private func previewStat(label: String, value: String, tint: Color?) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(tint ?? .primary)
            Text(label).font(.caption2).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func loadExistingForToday() {
        guard let log = todaysLog else { return }
        inBedDate = parseHHMM(log.inBed)
        lightsOutDate = parseHHMM(log.lightsOut)
        finalWakeDate = parseHHMM(log.finalWake)
        outBedDate = parseHHMM(log.outBed)
        latency = log.latency
        wakeCount = log.wakeCount
        wakeMin = log.wakeMin
        quality = Double(log.quality)
        mood = Double(log.mood)
        whoopStrain = log.whoopStrain
        whoopRecovery = log.whoopRecovery
        whoopHRV = log.whoopHRV
        whoopRHR = log.whoopRHR
    }

    private func save() {
        let date = todayISO()
        if let existing = todaysLog {
            // Update existing record in place
            existing.inBed = hhmmString(inBedDate)
            existing.lightsOut = hhmmString(lightsOutDate)
            existing.latency = latency
            existing.wakeCount = wakeCount
            existing.wakeMin = wakeMin
            existing.finalWake = hhmmString(finalWakeDate)
            existing.outBed = hhmmString(outBedDate)
            existing.quality = Int(quality)
            existing.mood = Int(mood)
            existing.whoopStrain = whoopStrain
            existing.whoopRecovery = whoopRecovery
            existing.whoopHRV = whoopHRV
            existing.whoopRHR = whoopRHR
        } else {
            let log = SleepLog(
                date: date,
                inBed: hhmmString(inBedDate),
                lightsOut: hhmmString(lightsOutDate),
                latency: latency,
                wakeCount: wakeCount,
                wakeMin: wakeMin,
                finalWake: hhmmString(finalWakeDate),
                outBed: hhmmString(outBedDate),
                quality: Int(quality),
                mood: Int(mood),
                whoopStrain: whoopStrain,
                whoopRecovery: whoopRecovery,
                whoopHRV: whoopHRV,
                whoopRHR: whoopRHR
            )
            context.insert(log)
        }
        try? context.save()
        saveFeedback = "Saved"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            saveFeedback = ""
        }
    }
}

// MARK: - time helpers

private func defaultTime(hour: Int, minute: Int) -> Date {
    var comps = DateComponents()
    comps.hour = hour
    comps.minute = minute
    return Calendar.current.date(from: comps) ?? Date()
}

private func hhmmString(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f.string(from: date)
}

private func parseHHMM(_ str: String) -> Date {
    let parts = str.split(separator: ":").compactMap { Int($0) }
    guard parts.count == 2 else { return Date() }
    return defaultTime(hour: parts[0], minute: parts[1])
}
