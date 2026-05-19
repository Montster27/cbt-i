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

    // Sleep stage breakdown held on the form between import and save.
    @State private var remMin: Int? = nil
    @State private var deepMin: Int? = nil
    @State private var lightMin: Int? = nil
    @State private var awakeStageMin: Int? = nil
    @State private var sleepCycles: Int? = nil
    @State private var hypnogramJSON: String? = nil

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
                VStack(alignment: .leading, spacing: 6) {
                    Text("MORNING LOG").kicker()
                    Text("How was the night?")
                        .font(.serifH1)
                        .foregroundStyle(Color.fg1)
                    Text("Estimates are fine — better than checking a clock.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fg3)
                        .padding(.top, 2)
                }
                .padding(.top, 4)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            if hasStageData {
                Section {
                    sleepDetailCard
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
            } else {
                Section {
                    SleepBlockViz(
                        tib: previewTIB,
                        latency: latency,
                        wakeMin: wakeMin,
                        inBed: hhmmString(inBedDate),
                        outBed: hhmmString(outBedDate)
                    )
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color.bgSurface)
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }

            Section {
                importRowIOS
            }
            .listRowBackground(Color.bgSurface)

            Section("Times") {
                formTimeRow("Got into bed", $inBedDate)
                formTimeRow("Lights out", $lightsOutDate)
                formTimeRow("Final wake-up", $finalWakeDate)
                formTimeRow("Out of bed", $outBedDate)
            }
            .listRowBackground(Color.bgSurface)

            Section("Night details") {
                formNumberRow("Minutes to fall asleep", value: $latency, range: 0...300)
                formNumberRow("Times woke", value: $wakeCount, range: 0...20)
                formNumberRow("Minutes awake", value: $wakeMin, range: 0...500)
            }
            .listRowBackground(Color.bgSurface)

            Section("Ratings") {
                formRatingRow("Sleep quality", value: $quality)
                formRatingRow("Morning mood", value: $mood)
            }
            .listRowBackground(Color.bgSurface)

            // Edge-to-edge visual preview card — three big numbers (only when stages aren't shown).
            if !hasStageData {
                Section {
                    previewCardIOS
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
            }

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
                    HStack(spacing: 8) {
                        Spacer()
                        if !saveFeedback.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                            Text(saveFeedback)
                        } else {
                            Image(systemName: "checkmark")
                            Text(todaysLog != nil ? "Update today's log" : "Save morning log")
                        }
                        Spacer()
                    }
                    .fontWeight(.semibold)
                    .padding(.vertical, 12)
                    .background(Color.warmAmber)
                    .foregroundStyle(Color(red: 0x06/255, green: 0x09/255, blue: 0x12/255))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 24, trailing: 16))
            }
        }
        .scrollContentBackground(.hidden)
        .appBackground()
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

                sleepDetailCard

                if !hasStageData {
                    previewCard
                }

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
    /// was off / Watch wasn't worn. For stage data we prefer HealthKit too, since
    /// it provides the sample-level hypnogram — Whoop only exposes totals.
    private func mergeDrafts(healthKit hk: SleepLogDraft?, whoop wh: SleepLogDraft?) -> SleepLogDraft? {
        guard let primary = hk ?? wh else { return nil }
        let stageSource = (hk?.remMin != nil || hk?.deepMin != nil || hk?.lightMin != nil) ? hk : wh
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
            whoopRHR: hk?.whoopRHR ?? wh?.whoopRHR,
            remMin: stageSource?.remMin,
            deepMin: stageSource?.deepMin,
            lightMin: stageSource?.lightMin,
            awakeMin: stageSource?.awakeMin,
            sleepCycles: wh?.sleepCycles,
            hypnogramJSON: hk?.hypnogramJSON
        )
    }

    private func applyImported(_ draft: SleepLogDraft) {
        inBedDate = parseHHMM(draft.inBed)
        lightsOutDate = parseHHMM(draft.lightsOut)
        finalWakeDate = parseHHMM(draft.finalWake)
        outBedDate = parseHHMM(draft.outBed)
        wakeCount = draft.wakeCount
        wakeMin = draft.wakeMin
        latency = draft.latency
        whoopStrain = draft.whoopStrain
        whoopRecovery = draft.whoopRecovery
        whoopHRV = draft.whoopHRV
        whoopRHR = draft.whoopRHR
        remMin = draft.remMin
        deepMin = draft.deepMin
        lightMin = draft.lightMin
        awakeStageMin = draft.awakeMin
        sleepCycles = draft.sleepCycles
        hypnogramJSON = draft.hypnogramJSON
        // Leave quality and mood for the user to fill — neither source provides those.
    }

    private var hasWhoopContext: Bool {
        whoopStrain != nil || whoopRecovery != nil || whoopHRV != nil || whoopRHR != nil
    }

    private var hasStageData: Bool {
        (remMin ?? 0) + (deepMin ?? 0) + (lightMin ?? 0) > 0
    }

    /// Reconstructs sleep window dates from the form's inBed / outBed for the hypnogram.
    /// Hypnogram events have full Date values from HealthKit; the window is anchored to today's
    /// log date so they align visually.
    private var sleepWindow: (start: Date, end: Date)? {
        guard hasStageData else { return nil }
        let events = Array<HypnogramEvent>.decode(hypnogramJSON)
        if let first = events.first, let last = events.last {
            return (first.start, last.end)
        }
        // No event-level data — approximate window from form times for the hypnogram axis labels.
        let cal = Calendar.current
        let today = Date()
        let inComps = cal.dateComponents([.hour, .minute], from: inBedDate)
        let outComps = cal.dateComponents([.hour, .minute], from: outBedDate)
        var startComps = cal.dateComponents([.year, .month, .day], from: today)
        startComps.hour = inComps.hour
        startComps.minute = inComps.minute
        var endComps = startComps
        endComps.hour = outComps.hour
        endComps.minute = outComps.minute
        guard let s = cal.date(from: startComps), var e = cal.date(from: endComps) else { return nil }
        if e <= s { e = e.addingTimeInterval(86_400) }
        return (s, e)
    }

    /// Apple/Whoop-style sleep detail block. Renders only when stage data is present
    /// (either from an import or carried over from a saved log).
    @ViewBuilder
    private var sleepDetailCard: some View {
        if hasStageData {
            let events = Array<HypnogramEvent>.decode(hypnogramJSON)
            let stageTST = (remMin ?? 0) + (deepMin ?? 0) + (lightMin ?? 0)
            let stageTIB = stageTST + (awakeStageMin ?? 0)
            let stageEff = stageTIB > 0 ? Int((Double(stageTST) / Double(stageTIB) * 100).rounded()) : previewSE
            let restorative = (remMin ?? 0) + (deepMin ?? 0)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.warmAmber)
                    Text("LAST NIGHT'S SLEEP").kicker()
                }

                SleepSummaryHero(
                    tstMin: stageTST,
                    tibMin: stageTIB,
                    restorativeMin: restorative > 0 ? restorative : nil,
                    efficiency: stageEff
                )

                if !events.isEmpty, let win = sleepWindow {
                    HypnogramView(events: events, windowStart: win.start, windowEnd: win.end)
                        .padding(.top, 4)
                } else if let win = sleepWindow {
                    Text("Sleep stages (no per-event data available)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fg4)
                    HypnogramView(
                        events: syntheticEvents(start: win.start, end: win.end),
                        windowStart: win.start,
                        windowEnd: win.end
                    )
                }

                Divider().background(Color.borderSoft)

                Text("TIME IN STAGES").kicker()
                StageBreakdownView(
                    remMin: remMin ?? 0,
                    deepMin: deepMin ?? 0,
                    lightMin: lightMin ?? 0,
                    awakeMin: awakeStageMin ?? 0
                )

                Divider().background(Color.borderSoft)

                HStack(alignment: .top, spacing: 16) {
                    AwakeningsCard(count: wakeCount, awakeMin: awakeStageMin ?? wakeMin)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let cycles = sleepCycles, cycles > 0 {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.skyAccent)
                                Text("CYCLES").kicker()
                            }
                            Text("\(cycles)")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(Color.fg1)
                                .monospacedDigit()
                            Text("sleep cycles")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.fg3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .warmCard()
        }
    }

    /// When we have stage totals but no event-level data (Whoop-only night), distribute
    /// the totals across the window in a reasonable cycle pattern so the hypnogram still
    /// communicates rough structure rather than appearing blank.
    private func syntheticEvents(start: Date, end: Date) -> [HypnogramEvent] {
        let totalSec = end.timeIntervalSince(start)
        let totalMin = totalSec / 60
        guard totalMin > 30 else { return [] }
        let rem = Double(remMin ?? 0)
        let deep = Double(deepMin ?? 0)
        let light = Double(lightMin ?? 0)
        let awake = Double(awakeStageMin ?? 0)
        let sumStages = rem + deep + light + awake
        guard sumStages > 0 else { return [] }

        // Build 5 buckets across the night with biologically-plausible weighting:
        // deep concentrated early, REM later, awake sprinkled, light always present.
        let cycles: [(SleepStage, Double)] = [
            (.light, light * 0.18), (.deep, deep * 0.35), (.light, light * 0.18), (.rem, rem * 0.12), (.awake, awake * 0.2),
            (.light, light * 0.18), (.deep, deep * 0.30), (.rem, rem * 0.18), (.light, light * 0.10), (.awake, awake * 0.15),
            (.light, light * 0.18), (.deep, deep * 0.20), (.rem, rem * 0.25), (.light, light * 0.12), (.awake, awake * 0.2),
            (.light, light * 0.16), (.deep, deep * 0.10), (.rem, rem * 0.25), (.light, light * 0.12), (.awake, awake * 0.2),
            (.light, light * 0.12), (.deep, deep * 0.05), (.rem, rem * 0.20), (.light, light * 0.30), (.awake, awake * 0.25),
        ]
        let normalizer = sumStages / cycles.reduce(0) { $0 + $1.1 }
        var cursor = start
        var out: [HypnogramEvent] = []
        for (stage, weight) in cycles {
            let dur = weight * normalizer * 60
            guard dur > 30 else { continue }
            let next = cursor.addingTimeInterval(dur)
            out.append(HypnogramEvent(stage: stage, start: cursor, end: min(next, end)))
            cursor = next
            if cursor >= end { break }
        }
        return out
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
                .font(.system(size: 18, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(tint ?? Color.fg1)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.fg4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.bgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.borderSoft, lineWidth: 1)
                )
        )
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
                .font(.system(size: 18, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(item.tint ?? Color.fg1)
            Text(item.label)
                .font(.system(size: 11))
                .foregroundStyle(Color.fg4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.bgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.borderSoft, lineWidth: 1)
                )
        )
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
        remMin = log.remMin
        deepMin = log.deepMin
        lightMin = log.lightMin
        awakeStageMin = log.awakeMin
        sleepCycles = log.sleepCycles
        hypnogramJSON = log.hypnogramJSON
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
            existing.remMin = remMin
            existing.deepMin = deepMin
            existing.lightMin = lightMin
            existing.awakeMin = awakeStageMin
            existing.sleepCycles = sleepCycles
            existing.hypnogramJSON = hypnogramJSON
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
                whoopRHR: whoopRHR,
                remMin: remMin,
                deepMin: deepMin,
                lightMin: lightMin,
                awakeMin: awakeStageMin,
                sleepCycles: sleepCycles,
                hypnogramJSON: hypnogramJSON
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
