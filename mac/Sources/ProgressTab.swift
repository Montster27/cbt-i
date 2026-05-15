import SwiftUI
import SwiftData
import Charts

struct ProgressTab: View {
    @Query(sort: \SleepLog.date) private var logs: [SleepLog]

    var recentLogs: [SleepLog] { Array(logs.suffix(14)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Progress")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    exportMenu
                        .disabled(logs.isEmpty)
                }

                if logs.count < 2 {
                    emptyState
                } else {
                    statsRow
                    if let avg = logs.recent5AvgSE {
                        advisoryBanner(avg: avg)
                    }
                    chartSection(
                        title: "Sleep efficiency (last 14 nights)",
                        yDomain: 0...100,
                        valueFormatter: { "\($0)%" },
                        referenceLine: 85,
                        color: Color(red: 0x18/255, green: 0x5F/255, blue: 0xA5/255),
                        values: recentLogs.map { (log: $0, y: Double($0.se)) }
                    )
                    chartSection(
                        title: "Sleep quality rating",
                        yDomain: 1...10,
                        valueFormatter: { "\(Int($0))/10" },
                        referenceLine: nil,
                        color: Color(red: 0x1D/255, green: 0x9E/255, blue: 0x75/255),
                        values: recentLogs.map { (log: $0, y: Double($0.quality)) }
                    )

                    if recentLogs.contains(where: { $0.whoopRecovery != nil || $0.whoopStrain != nil }) {
                        recoveryStrainChart
                    }
                }
            }
            .padding(20)
        }
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
            Text("Log at least 2 nights to see your progress charts.")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("The Morning Log tab has a dot next to it when today hasn't been logged yet.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 32)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statBox("Current week", "Week \(weekNumber(from: logs))")
            statBox("Nights logged", "\(logs.count)")
            statBox("5-night avg SE", logs.recent5AvgSE.map { "\($0)%" } ?? "—")
        }
    }

    private func statBox(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.title3).fontWeight(.medium)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline).fontWeight(.medium)
            Chart {
                ForEach(values, id: \.log.persistentModelID) { item in
                    LineMark(
                        x: .value("Date", String(item.log.date.suffix(5))),
                        y: .value(title, item.y)
                    )
                    .foregroundStyle(color)
                    .symbol(.circle)
                }
                if let ref = referenceLine {
                    RuleMark(y: .value("Target", ref))
                        .foregroundStyle(Color(red: 0x3B/255, green: 0x6D/255, blue: 0x11/255))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 2]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("\(Int(ref))%")
                                .font(.caption2)
                                .foregroundStyle(Color(red: 0x3B/255, green: 0x6D/255, blue: 0x11/255))
                        }
                }
            }
            .chartYScale(domain: yDomain)
            .frame(height: 180)
        }
    }
}

private enum BannerTone { case success, warning }
