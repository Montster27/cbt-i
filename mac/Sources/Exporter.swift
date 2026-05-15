#if os(macOS)
import AppKit
#endif
import Foundation
import UniformTypeIdentifiers

enum ExportFormat {
    case markdown
    case csv

    var suggestedFilename: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let today = f.string(from: Date())
        switch self {
        case .markdown: return "cbti-report-\(today).md"
        case .csv:      return "cbti-data-\(today).csv"
        }
    }

    var contentType: UTType {
        switch self {
        case .markdown: return .plainText
        case .csv:      return UTType(filenameExtension: "csv") ?? .plainText
        }
    }
}

enum Exporter {

    static func export(logs: [SleepLog], startDate: String?, format: ExportFormat) {
        let content: String
        switch format {
        case .markdown: content = markdownReport(logs: logs, startDate: startDate)
        case .csv:      content = csvReport(logs: logs)
        }
        #if os(macOS)
        savePanel(content: content, format: format)
        #else
        // Phase 8 will wire this up via ShareLink / UIDocumentPicker on iOS/iPadOS.
        NSLog("[Export] iOS export not yet wired. Format: %@, %d chars.", String(describing: format), content.count)
        #endif
    }

    // MARK: - Generated content (cross-platform)

    /// Returns the export content as a string for callers that want to write or share themselves.
    /// Used by iOS/iPadOS ShareLink in Phase 8.
    static func content(logs: [SleepLog], startDate: String?, format: ExportFormat) -> String {
        switch format {
        case .markdown: return markdownReport(logs: logs, startDate: startDate)
        case .csv:      return csvReport(logs: logs)
        }
    }

    #if os(macOS)
    // MARK: - Save panel (macOS only)

    private static func savePanel(content: String, format: ExportFormat) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = format.suggestedFilename
        panel.allowedContentTypes = [format.contentType]
        panel.canCreateDirectories = true
        panel.title = "Export CBT-I report"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }
    #endif

    // MARK: - Markdown

    private static func markdownReport(logs: [SleepLog], startDate: String?) -> String {
        var out = ""
        let df = DateFormatter()
        df.dateStyle = .long

        out += "# CBT-I Sleep Activity Report\n\n"
        out += "Generated: \(df.string(from: Date()))  \n"
        if let start = startDate {
            out += "Program start: \(start)  \n"
            out += "Current week: \(weekNumber(startDate: start)) of 6  \n"
        }
        out += "\n"

        out += "## Summary\n\n"
        if logs.isEmpty {
            out += "_No nights logged yet._\n\n"
            return out
        }

        let allSE = logs.map { $0.se }
        let allTIB = logs.map { $0.tib }
        let allTST = logs.map { $0.tst }

        let avgSE = Int((Double(allSE.reduce(0, +)) / Double(logs.count)).rounded())
        let recent5 = Array(logs.suffix(5))
        let recent5AvgSE = recent5.isEmpty ? 0 : Int((Double(recent5.map { $0.se }.reduce(0, +)) / Double(recent5.count)).rounded())
        let avgTIB = allTIB.reduce(0, +) / logs.count
        let avgTST = allTST.reduce(0, +) / logs.count

        out += "- Nights logged: **\(logs.count)**\n"
        out += "- Average sleep efficiency (all nights): **\(avgSE)%**\n"
        out += "- Average sleep efficiency (last 5 nights): **\(recent5AvgSE)%**\n"
        out += "- Average time in bed: **\(formatDurationMinutes(avgTIB))**\n"
        out += "- Average estimated sleep: **\(formatDurationMinutes(avgTST))**\n"
        out += "- Best night SE: **\(allSE.max() ?? 0)%**\n"
        out += "- Worst night SE: **\(allSE.min() ?? 0)%**\n\n"

        // Whoop summary — only show if any night has data.
        let recoveryValues = logs.compactMap(\.whoopRecovery)
        let strainValues = logs.compactMap(\.whoopStrain)
        if !recoveryValues.isEmpty || !strainValues.isEmpty {
            out += "## Activity & recovery (from Whoop)\n\n"
            if !recoveryValues.isEmpty {
                let avgRec = Int((Double(recoveryValues.reduce(0, +)) / Double(recoveryValues.count)).rounded())
                out += "- Average recovery score: **\(avgRec)%**\n"
            }
            if !strainValues.isEmpty {
                let avgStrain = strainValues.reduce(0, +) / Double(strainValues.count)
                out += "- Average daily strain: **\(String(format: "%.1f", avgStrain))** / 21\n"
            }
            out += "\n"
        }

        out += "## Nightly log\n\n"
        out += "| Date | In bed | Out bed | TIB | TST | SE | Wakes | Quality | Mood | Strain | Recovery |\n"
        out += "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |\n"
        for log in logs {
            out += "| \(log.date)"
            out += " | \(formatTime12h(log.inBed))"
            out += " | \(formatTime12h(log.outBed))"
            out += " | \(formatDurationMinutes(log.tib))"
            out += " | \(formatDurationMinutes(log.tst))"
            out += " | \(log.se)%"
            out += " | \(log.wakeCount) (\(log.wakeMin)m)"
            out += " | \(log.quality)/10"
            out += " | \(log.mood)/10"
            out += " | \(log.whoopStrain.map { String(format: "%.1f", $0) } ?? "—")"
            out += " | \(log.whoopRecovery.map { "\($0)%" } ?? "—") |\n"
        }
        out += "\n"

        return out
    }

    // MARK: - CSV

    private static func csvReport(logs: [SleepLog]) -> String {
        var out = "date,in_bed,lights_out,latency_min,wake_count,wake_min,final_wake,out_bed,tib_min,tst_min,sleep_efficiency_pct,quality,mood,whoop_strain,whoop_recovery_pct,whoop_hrv_ms,whoop_rhr_bpm\n"
        for log in logs {
            out += "\(log.date)"
            out += ",\(log.inBed)"
            out += ",\(log.lightsOut)"
            out += ",\(log.latency)"
            out += ",\(log.wakeCount)"
            out += ",\(log.wakeMin)"
            out += ",\(log.finalWake)"
            out += ",\(log.outBed)"
            out += ",\(log.tib)"
            out += ",\(log.tst)"
            out += ",\(log.se)"
            out += ",\(log.quality)"
            out += ",\(log.mood)"
            out += ",\(log.whoopStrain.map { String(format: "%.2f", $0) } ?? "")"
            out += ",\(log.whoopRecovery.map { String($0) } ?? "")"
            out += ",\(log.whoopHRV.map { String(format: "%.1f", $0) } ?? "")"
            out += ",\(log.whoopRHR.map { String($0) } ?? "")\n"
        }
        return out
    }
}
