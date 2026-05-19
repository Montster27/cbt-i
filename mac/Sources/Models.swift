import Foundation
import SwiftData
import SwiftUI

@Model
final class SleepLog {
    var date: String = ""       // "yyyy-MM-dd" — logical primary key, enforced in code
    var inBed: String = ""
    var lightsOut: String = ""
    var latency: Int = 0
    var wakeCount: Int = 0
    var wakeMin: Int = 0
    var finalWake: String = ""
    var outBed: String = ""
    var quality: Int = 5
    var mood: Int = 5

    // Optional Whoop enrichment. Nil when log was entered manually or strap was off.
    var whoopStrain: Double? = nil        // 0–21 day strain score
    var whoopRecovery: Int? = nil         // 0–100 morning recovery score
    var whoopHRV: Double? = nil           // milliseconds (rMSSD)
    var whoopRHR: Int? = nil              // resting heart rate, bpm

    // Optional sleep-stage breakdown from HealthKit (Apple Watch) or Whoop.
    // All in minutes. Nil when log was manual or stage data unavailable.
    var remMin: Int? = nil
    var deepMin: Int? = nil               // Apple "Deep", Whoop "Slow Wave"
    var lightMin: Int? = nil              // Apple "Core", Whoop "Light"
    var awakeMin: Int? = nil              // Stage-derived awake total (more accurate than wakeMin manual entry)
    var sleepCycles: Int? = nil           // Whoop-only
    /// JSON-encoded `[HypnogramEvent]` (start ISO, end ISO, stage). Only HealthKit
    /// provides sample-level data — Whoop API exposes totals only.
    var hypnogramJSON: String? = nil

    init(
        date: String,
        inBed: String,
        lightsOut: String,
        latency: Int,
        wakeCount: Int,
        wakeMin: Int,
        finalWake: String,
        outBed: String,
        quality: Int,
        mood: Int,
        whoopStrain: Double? = nil,
        whoopRecovery: Int? = nil,
        whoopHRV: Double? = nil,
        whoopRHR: Int? = nil,
        remMin: Int? = nil,
        deepMin: Int? = nil,
        lightMin: Int? = nil,
        awakeMin: Int? = nil,
        sleepCycles: Int? = nil,
        hypnogramJSON: String? = nil
    ) {
        self.date = date
        self.inBed = inBed
        self.lightsOut = lightsOut
        self.latency = latency
        self.wakeCount = wakeCount
        self.wakeMin = wakeMin
        self.finalWake = finalWake
        self.outBed = outBed
        self.quality = quality
        self.mood = mood
        self.whoopStrain = whoopStrain
        self.whoopRecovery = whoopRecovery
        self.whoopHRV = whoopHRV
        self.whoopRHR = whoopRHR
        self.remMin = remMin
        self.deepMin = deepMin
        self.lightMin = lightMin
        self.awakeMin = awakeMin
        self.sleepCycles = sleepCycles
        self.hypnogramJSON = hypnogramJSON
    }
}

/// Plain-value snapshot of a sleep log, used for transient form state and external imports
/// before deciding to persist a SleepLog @Model record.
struct SleepLogDraft {
    var date: String
    var inBed: String
    var lightsOut: String
    var latency: Int
    var wakeCount: Int
    var wakeMin: Int
    var finalWake: String
    var outBed: String
    var quality: Int
    var mood: Int

    var whoopStrain: Double? = nil
    var whoopRecovery: Int? = nil
    var whoopHRV: Double? = nil
    var whoopRHR: Int? = nil

    var remMin: Int? = nil
    var deepMin: Int? = nil
    var lightMin: Int? = nil
    var awakeMin: Int? = nil
    var sleepCycles: Int? = nil
    var hypnogramJSON: String? = nil
}

// MARK: - Sleep stages

enum SleepStage: String, Codable, CaseIterable {
    case awake
    case rem
    case light    // Apple "Core" / Whoop "Light"
    case deep     // Apple "Deep" / Whoop "Slow Wave"

    var displayName: String {
        switch self {
        case .awake: return "Awake"
        case .rem:   return "REM"
        case .light: return "Core"
        case .deep:  return "Deep"
        }
    }

    /// Apple Health uses warm/red for Awake and a blue ramp (light → dark) for sleep depth.
    /// Tuned to read against the warm dark surface.
    var color: Color {
        switch self {
        case .awake: return Color(red: 0xE5/255, green: 0x9A/255, blue: 0x6E/255)
        case .rem:   return Color(red: 0xA8/255, green: 0xC8/255, blue: 0xEB/255)
        case .light: return Color(red: 0x5A/255, green: 0x92/255, blue: 0xD0/255)
        case .deep:  return Color(red: 0x2F/255, green: 0x4F/255, blue: 0x8E/255)
        }
    }
}

/// One contiguous span of a single sleep stage. Stored as a flat array per night
/// in `SleepLog.hypnogramJSON`.
struct HypnogramEvent: Codable {
    let stage: SleepStage
    let start: Date
    let end: Date

    var minutes: Int { max(0, Int(end.timeIntervalSince(start) / 60)) }
}

extension Array where Element == HypnogramEvent {
    /// Encode to compact JSON for storage.
    var jsonString: String? {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        guard let data = try? enc.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func decode(_ json: String?) -> [HypnogramEvent] {
        guard let json, let data = json.data(using: .utf8) else { return [] }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return (try? dec.decode([HypnogramEvent].self, from: data)) ?? []
    }
}

// MARK: - Computed metrics

extension SleepLog {
    /// Time in bed, in minutes.
    var tib: Int {
        var out = outBed.hhmmMinutes
        let inB = inBed.hhmmMinutes
        if out <= inB { out += 1440 }
        return out - inB
    }

    /// Total sleep time, in minutes.
    var tst: Int { max(0, tib - latency - wakeMin) }

    /// Sleep efficiency, 0–100.
    var se: Int {
        guard tib > 0 else { return 0 }
        return Int((Double(tst) / Double(tib) * 100).rounded())
    }

    var hoursDecimal: Double {
        (Double(tst) / 60.0 * 10).rounded() / 10
    }

    /// True when this log has any stage breakdown to display.
    var hasStageData: Bool {
        (remMin ?? 0) + (deepMin ?? 0) + (lightMin ?? 0) > 0
    }

    /// Stage-derived total sleep time (rem + light + deep). Falls back to `tst` if unavailable.
    /// More accurate than the `tst` calculation when stages are present, because TIB excludes
    /// only manual latency/wake estimates.
    var tstFromStages: Int? {
        guard hasStageData else { return nil }
        return (remMin ?? 0) + (deepMin ?? 0) + (lightMin ?? 0)
    }

    /// REM + Deep — Whoop's "restorative sleep" metric.
    var restorativeMin: Int? {
        guard let r = remMin, let d = deepMin else { return nil }
        return r + d
    }

    var hypnogram: [HypnogramEvent] {
        Array<HypnogramEvent>.decode(hypnogramJSON)
    }
}

// MARK: - Collection helpers

extension Array where Element == SleepLog {
    /// Returns logs sorted ascending by date.
    var sortedByDate: [SleepLog] {
        sorted { $0.date < $1.date }
    }

    /// Last 5 logs by date.
    var recent5: [SleepLog] {
        Array(sortedByDate.suffix(5))
    }

    /// Average sleep efficiency of the last 5 logs, nil if empty.
    var recent5AvgSE: Int? {
        let r = recent5
        guard !r.isEmpty else { return nil }
        let sum = r.reduce(0) { $0 + $1.se }
        return Int((Double(sum) / Double(r.count)).rounded())
    }

    /// Earliest date string ("yyyy-MM-dd") in the logs, nil if empty.
    var earliestDate: String? {
        map(\.date).min()
    }
}

// MARK: - String / date helpers

extension String {
    var hhmmMinutes: Int {
        let parts = split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return 0 }
        return parts[0] * 60 + parts[1]
    }
}

func minutesToHHMM(_ mins: Int) -> String {
    let m = ((mins % 1440) + 1440) % 1440
    return String(format: "%02d:%02d", m / 60, m % 60)
}

func formatTime12h(_ hhmm: String) -> String {
    let parts = hhmm.split(separator: ":").compactMap { Int($0) }
    guard parts.count == 2 else { return hhmm }
    let h = parts[0]
    let m = parts[1]
    let h12 = h % 12 == 0 ? 12 : h % 12
    let ampm = h >= 12 ? "PM" : "AM"
    return String(format: "%d:%02d %@", h12, m, ampm)
}

func formatDurationMinutes(_ mins: Int) -> String {
    "\(mins / 60)h \(mins % 60)m"
}

func todayISO() -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f.string(from: Date())
}

/// Current week of the 6-week program based on the supplied program-start date.
/// Returns 1 if startDate is nil or invalid.
func weekNumber(startDate: String?) -> Int {
    guard let startDate else { return 1 }
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    guard let start = f.date(from: startDate) else { return 1 }
    let days = Date().timeIntervalSince(start) / 86400
    let weeksElapsed = Int(floor(days / 7))
    return min(6, weeksElapsed + 1)
}

/// Convenience for views that have a `[SleepLog]` in hand.
func weekNumber(from logs: [SleepLog]) -> Int {
    weekNumber(startDate: logs.earliestDate)
}

func seColor(_ se: Int) -> (red: Double, green: Double, blue: Double) {
    if se >= 85 { return (0x3B / 255.0, 0x6D / 255.0, 0x11 / 255.0) }
    if se >= 75 { return (0x85 / 255.0, 0x4F / 255.0, 0x0B / 255.0) }
    return (0xA3 / 255.0, 0x2D / 255.0, 0x2D / 255.0)
}

/// Whoop convention: green 67+, yellow 34–66, red 0–33.
func recoveryColor(_ r: Int) -> Color {
    if r >= 67 { return Color(red: 0x3B/255, green: 0x6D/255, blue: 0x11/255) }
    if r >= 34 { return Color(red: 0x85/255, green: 0x4F/255, blue: 0x0B/255) }
    return Color(red: 0xA3/255, green: 0x2D/255, blue: 0x2D/255)
}

/// Whoop strain bands: 0–9 low (blue), 10–13 moderate (cyan), 14–17 high (orange), 18+ all-out (red).
func strainColor(_ s: Double) -> Color {
    if s >= 18 { return Color(red: 0xA3/255, green: 0x2D/255, blue: 0x2D/255) }
    if s >= 14 { return Color(red: 0x85/255, green: 0x4F/255, blue: 0x0B/255) }
    if s >= 10 { return Color(red: 0x18/255, green: 0x5F/255, blue: 0xA5/255) }
    return Color(red: 0x2A/255, green: 0x7B/255, blue: 0x9E/255)
}
