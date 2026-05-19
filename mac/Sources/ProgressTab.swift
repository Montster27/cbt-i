import SwiftUI
import SwiftData
import Charts

struct ProgressTab: View {
    @Query(sort: \SleepLog.date) private var logs: [SleepLog]

    var recentLogs: [SleepLog] { Array(logs.suffix(14)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                if logs.count < 2 {
                    emptyState
                } else {
                    if let avg = logs.recent5AvgSE {
                        ringsHero(avg: avg)
                    }
                    chartSection(
                        title: "Sleep efficiency",
                        yDomain: 0...100,
                        valueFormatter: { "\($0)%" },
                        referenceLine: 85,
                        color: Color.warmAmber,
                        values: recentLogs.map { (log: $0, y: Double($0.se)) }
                    )
                    chartSection(
                        title: "Sleep quality",
                        yDomain: 1...10,
                        valueFormatter: { "\(Int($0))/10" },
                        referenceLine: nil,
                        color: Color.skyAccent,
                        values: recentLogs.map { (log: $0, y: Double($0.quality)) }
                    )
                    statsRow

                    if recentLogs.contains(where: { $0.hasStageData }) {
                        sleepStagesChart
                    }

                    if recentLogs.contains(where: { $0.whoopRecovery != nil || $0.whoopStrain != nil }) {
                        recoveryStrainChart
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 36)
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) { exportMenu.disabled(logs.isEmpty) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(logs.count) NIGHTS").kicker()
            Text(headerTitle)
                .font(.serifH1)
                .foregroundStyle(Color.fg1)
                .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headerTitle: String {
        guard let avg = logs.recent5AvgSE else { return "Your sleep journey." }
        if avg >= 85 { return "Your sleep is consolidating." }
        if avg >= 75 { return "Steady progress — hold the line." }
        return "Build pressure. It will land."
    }

    private func ringsHero(avg: Int) -> some View {
        HStack(spacing: 16) {
            ProgressRing(value: Double(avg), size: 110, stroke: 10, color: Color.seSwiftUIColor(avg)) {
                VStack(spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("\(avg)")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(Color.fg1)
                            .monospacedDigit()
                        Text("%").font(.system(size: 13)).foregroundStyle(Color.fg3)
                    }
                    Text("5-night SE").font(.system(size: 11)).foregroundStyle(Color.fg4)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                let label = avg >= 85 ? "ON TARGET" : avg >= 75 ? "BUILDING" : "HOLD POSITION"
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Color.seSwiftUIColor(avg))
                let body = avg >= 85
                    ? "You've crossed 85% — time to expand the window."
                    : avg >= 75
                        ? "Improvement is happening. Don't go to bed early."
                        : "Sleep pressure is the engine. Keep restriction strict."
                Text(body)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.fg2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.warmAmber.opacity(0.10), Color(red: 0x16/255, green: 0x20/255, blue: 0x3A/255).opacity(0.3)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.borderSoft, lineWidth: 1)
                )
        )
    }

    private var exportMenu: some View {
        Menu {
            #if os(macOS)
            Button("Markdown report…") {
                Exporter.export(logs: logs, startDate: logs.earliestDate, format: .markdown)
            }
            Button("CSV (raw data)…") {
                Exporter.export(logs: logs, startDate: logs.earliestDate, format: .csv)
            }
            #else
            ShareLink(item: tempFileURL(for: .markdown), preview: SharePreview("CBT-I sleep report")) {
                Label("Markdown report…", systemImage: "doc.text")
            }
            ShareLink(item: tempFileURL(for: .csv), preview: SharePreview("CBT-I sleep data")) {
                Label("CSV (raw data)…", systemImage: "tablecells")
            }
            #endif
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        #if os(macOS)
        .menuStyle(.borderlessButton)
        .fixedSize()
        #endif
    }

    #if os(iOS)
    /// Writes the export content to a temp file and returns its URL so ShareLink can hand
    /// it to the Share Sheet (Save to Files, AirDrop, Mail, etc.). The file is regenerated
    /// on each render — cheap given typical journal size.
    private func tempFileURL(for format: ExportFormat) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(format.suggestedFilename)
        let content = Exporter.content(logs: logs, startDate: logs.earliestDate, format: format)
        try? content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    #endif

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log at least 2 nights to see your progress.")
                .font(.system(size: 14))
                .foregroundStyle(Color.fg2)
            Text("The Morning Log tab has a dot when today hasn't been logged yet.")
                .font(.system(size: 12))
                .foregroundStyle(Color.fg4)
        }
        .warmCard()
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statBox("Current", "Week \(weekNumber(from: logs))")
            statBox("Logged", "\(logs.count)")
            statBox("5-night SE", logs.recent5AvgSE.map { "\($0)%" } ?? "—")
        }
    }

    private func statBox(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.fg1)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.fg4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.bgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.borderSoft, lineWidth: 1)
                )
        )
    }

    private func advisoryBanner(avg: Int) -> some View {
        let (tone, message): (BannerTone, String) = {
            if avg >= 85 {
                let earlier = minutesToHHMM("23:45".hhmmMinutes - 15)
                return (.success, "SE ≥85% — move bedtime earlier to \(formatTime12h(earlier)) for the next 5 nights.")
            } else if avg >= 75 {
                return (.warning, "SE 75–84% — stay at current window. Improvement is happening, hold the line.")
            } else {
                return (.warning, "SE below 75% — maintain strict sleep restriction. Don't go to bed early. The pressure is building.")
            }
        }()

        let bg: Color
        let stroke: Color
        let textColor: Color
        switch tone {
        case .success:
            bg = Color(red: 0xE7/255, green: 0xF0/255, blue: 0xDF/255)
            stroke = Color(red: 0xBF/255, green: 0xD4/255, blue: 0xA5/255)
            textColor = Color(red: 0x3B/255, green: 0x6D/255, blue: 0x11/255)
        case .warning:
            bg = Color(red: 0xF8/255, green: 0xEC/255, blue: 0xDD/255)
            stroke = Color(red: 0xE5/255, green: 0xC8/255, blue: 0x96/255)
            textColor = Color(red: 0x85/255, green: 0x4F/255, blue: 0x0B/255)
        }

        return Text(message)
            .font(.callout)
            .foregroundStyle(textColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(stroke, lineWidth: 0.5))
    }

    /// Stacked-bar trend — one bar per night, stages from bottom up: Deep, Core (Light),
    /// REM, Awake. Matches Apple Health's "Sleep stages over time" view.
    private var sleepStagesChart: some View {
        let stagedLogs = recentLogs.filter { $0.hasStageData }
        let avgRestorative: Int = {
            let vals = stagedLogs.compactMap { $0.restorativeMin }
            guard !vals.isEmpty else { return 0 }
            return vals.reduce(0, +) / vals.count
        }()

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sleep stages")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.fg1)
                Spacer()
                if avgRestorative > 0 {
                    WarmChip(text: "Avg restorative \(avgRestorative / 60)h \(avgRestorative % 60)m")
                }
            }
            Text(stagedLogs.count > 14 ? "Last 14 nights" : "\(stagedLogs.count) nights")
                .font(.system(size: 11))
                .foregroundStyle(Color.fg4)

            Chart {
                ForEach(stagedLogs, id: \.persistentModelID) { log in
                    let dateLabel = String(log.date.suffix(5))
                    BarMark(
                        x: .value("Date", dateLabel),
                        y: .value("Deep", Double(log.deepMin ?? 0) / 60.0),
                        stacking: .standard
                    )
                    .foregroundStyle(by: .value("Stage", SleepStage.deep.displayName))

                    BarMark(
                        x: .value("Date", dateLabel),
                        y: .value("Core", Double(log.lightMin ?? 0) / 60.0),
                        stacking: .standard
                    )
                    .foregroundStyle(by: .value("Stage", SleepStage.light.displayName))

                    BarMark(
                        x: .value("Date", dateLabel),
                        y: .value("REM", Double(log.remMin ?? 0) / 60.0),
                        stacking: .standard
                    )
                    .foregroundStyle(by: .value("Stage", SleepStage.rem.displayName))

                    BarMark(
                        x: .value("Date", dateLabel),
                        y: .value("Awake", Double(log.awakeMin ?? 0) / 60.0),
                        stacking: .standard
                    )
                    .foregroundStyle(by: .value("Stage", SleepStage.awake.displayName))
                }
            }
            .chartForegroundStyleScale([
                SleepStage.deep.displayName:  SleepStage.deep.color,
                SleepStage.light.displayName: SleepStage.light.color,
                SleepStage.rem.displayName:   SleepStage.rem.color,
                SleepStage.awake.displayName: SleepStage.awake.color,
            ])
            .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(Color.fg4)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(Color.borderSoft)
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .foregroundStyle(Color.fg4)
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .warmCard()
    }

    private var recoveryStrainChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Text("Activity vs. sleep")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                legendChip("Strain", color: Color(red: 0x18/255, green: 0x5F/255, blue: 0xA5/255))
                legendChip("Recovery", color: Color(red: 0x3B/255, green: 0x6D/255, blue: 0x11/255))
                legendChip("Sleep eff", color: Color.secondary)
            }
            Chart {
                ForEach(recentLogs, id: \.persistentModelID) { log in
                    let dateLabel = String(log.date.suffix(5))
                    if let strain = log.whoopStrain {
                        // Strain is on a 0–21 scale; map to 0–100 visually so it shares the axis.
                        BarMark(
                            x: .value("Date", dateLabel),
                            y: .value("Strain", strain / 21.0 * 100)
                        )
                        .foregroundStyle(Color(red: 0x18/255, green: 0x5F/255, blue: 0xA5/255).opacity(0.55))
                        .annotation(position: .top, alignment: .center, spacing: 1) {
                            Text(String(format: "%.0f", strain))
                                .font(.system(size: 8))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    if let rec = log.whoopRecovery {
                        LineMark(
                            x: .value("Date", dateLabel),
                            y: .value("Recovery", Double(rec)),
                            series: .value("Series", "Recovery")
                        )
                        .foregroundStyle(Color(red: 0x3B/255, green: 0x6D/255, blue: 0x11/255))
                        .symbol(.circle)
                    }
                    LineMark(
                        x: .value("Date", dateLabel),
                        y: .value("SE", Double(log.se)),
                        series: .value("Series", "SE")
                    )
                    .foregroundStyle(Color.secondary.opacity(0.55))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                }
            }
            .chartYScale(domain: 0...100)
            .frame(height: 200)
            Text("Strain (yesterday's activity) is shown scaled to the same axis as recovery and sleep efficiency for visual correlation.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func legendChip(_ label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func chartSection(
        title: String,
        yDomain: ClosedRange<Double>,
        valueFormatter: @escaping (Double) -> String,
        referenceLine: Double?,
        color: Color,
        values: [(log: SleepLog, y: Double)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.fg1)
                Spacer()
                if let avg = logs.recent5AvgSE, title == "Sleep efficiency" {
                    WarmChip(text: "Avg \(avg)%")
                }
            }
            Text(values.count > 14 ? "Last 14 nights" : "\(values.count) nights")
                .font(.system(size: 11))
                .foregroundStyle(Color.fg4)
            Chart {
                ForEach(values, id: \.log.persistentModelID) { item in
                    BarMark(
                        x: .value("Date", String(item.log.date.suffix(5))),
                        y: .value(title, item.y)
                    )
                    .foregroundStyle(by: .value("SE band", item.y >= 85 ? "good" : item.y >= 75 ? "warn" : "crit"))
                }
                if let ref = referenceLine {
                    RuleMark(y: .value("Target", ref))
                        .foregroundStyle(Color.good400.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 2]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text(valueFormatter(ref))
                                .font(.system(size: 10))
                                .foregroundStyle(Color.good400)
                        }
                }
            }
            .chartForegroundStyleScale([
                "good": Color.good400.opacity(0.85),
                "warn": Color.warn400.opacity(0.85),
                "crit": Color.crit400.opacity(0.85),
            ])
            .chartLegend(.hidden)
            .chartYScale(domain: yDomain)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(Color.fg4)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Color.borderSoft)
                    AxisValueLabel().foregroundStyle(Color.fg4)
                }
            }
            .frame(height: 160)
        }
        .warmCard()
    }
}

private enum BannerTone { case success, warning }
