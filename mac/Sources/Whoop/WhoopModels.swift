import Foundation

struct WhoopSleepPage: Decodable {
    let records: [WhoopSleep]
    let next_token: String?
}

struct WhoopSleep: Decodable {
    let id: String
    let cycle_id: Int?             // links to /v2/cycle/{id} and recovery
    let start: String              // ISO 8601 with fractional seconds, UTC
    let end: String
    let timezone_offset: String    // "-05:00" or "+00:00"
    let nap: Bool
    let score_state: String
    let score: WhoopSleepScore?
}

// MARK: - Cycle (daily strain)

struct WhoopCycle: Decodable {
    let id: Int
    let user_id: Int?
    let start: String
    let end: String?               // nil while cycle is in progress
    let timezone_offset: String?
    let score_state: String
    let score: WhoopCycleScore?
}

struct WhoopCycleScore: Decodable {
    let strain: Double?
    let kilojoule: Double?
    let average_heart_rate: Int?
    let max_heart_rate: Int?
}

// MARK: - Recovery

struct WhoopRecovery: Decodable {
    let cycle_id: Int?
    let sleep_id: String?
    let user_id: Int?
    let score_state: String
    let score: WhoopRecoveryScore?
}

struct WhoopRecoveryScore: Decodable {
    let user_calibrating: Bool?
    let recovery_score: Double?       // 0–100
    let resting_heart_rate: Double?
    let hrv_rmssd_milli: Double?
    let spo2_percentage: Double?
    let skin_temp_celsius: Double?
}

struct WhoopSleepScore: Decodable {
    let stage_summary: WhoopStageSummary?
    let sleep_efficiency_percentage: Double?
}

struct WhoopStageSummary: Decodable {
    let total_in_bed_time_milli: Int?
    let total_awake_time_milli: Int?
    let total_light_sleep_time_milli: Int?
    let total_slow_wave_sleep_time_milli: Int?
    let total_rem_sleep_time_milli: Int?
    let sleep_cycle_count: Int?
    let disturbance_count: Int?
}

struct WhoopTokenResponse: Decodable {
    let access_token: String
    let refresh_token: String?
    let expires_in: Int
    let scope: String?
    let token_type: String
}

// MARK: - mapping to SleepLog

extension WhoopSleep {
    /// Convert Whoop sleep activity into a partially-filled draft.
    /// Returns nil if the response is missing required time fields.
    /// latency, quality, and mood are left at defaults — Whoop doesn't expose those.
    /// Pass `cycle` to enrich with strain, and `recovery` to enrich with recovery score / HRV / RHR.
    func toDraft(cycle: WhoopCycle? = nil, recovery: WhoopRecovery? = nil) -> SleepLogDraft? {
        guard
            let startDate = parseWhoopTimestamp(start),
            let endDate = parseWhoopTimestamp(end)
        else { return nil }

        // Apply the recorded timezone offset so times match the user's local clock.
        let offset = parseTimezoneOffset(timezone_offset) ?? TimeZone.current.secondsFromGMT()
        let localStart = startDate.addingTimeInterval(TimeInterval(offset))
        let localEnd = endDate.addingTimeInterval(TimeInterval(offset))

        let utcCal = utcCalendar()

        let inBed = hhmmStringFromDate(localStart, calendar: utcCal)
        let outBed = hhmmStringFromDate(localEnd, calendar: utcCal)
        let dateString = ymdStringFromDate(localEnd, calendar: utcCal)

        let awakeMs = score?.stage_summary?.total_awake_time_milli ?? 0
        let disturbances = score?.stage_summary?.disturbance_count ?? 0

        return SleepLogDraft(
            date: dateString,
            inBed: inBed,
            lightsOut: inBed,
            latency: 0,
            wakeCount: disturbances,
            wakeMin: awakeMs / 60_000,
            finalWake: outBed,
            outBed: outBed,
            quality: 5,
            mood: 5,
            whoopStrain: cycle?.score?.strain,
            whoopRecovery: recovery?.score?.recovery_score.map { Int($0.rounded()) },
            whoopHRV: recovery?.score?.hrv_rmssd_milli,
            whoopRHR: recovery?.score?.resting_heart_rate.map { Int($0.rounded()) }
        )
    }
}

private func parseWhoopTimestamp(_ s: String) -> Date? {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = f.date(from: s) { return d }
    f.formatOptions = [.withInternetDateTime]
    return f.date(from: s)
}

private func parseTimezoneOffset(_ s: String) -> Int? {
    // Accept "-05:00", "+00:00", "Z"
    if s == "Z" { return 0 }
    let sign: Int
    var rest = s
    if rest.first == "-" { sign = -1; rest.removeFirst() }
    else if rest.first == "+" { sign = 1; rest.removeFirst() }
    else { sign = 1 }
    let parts = rest.split(separator: ":").compactMap { Int($0) }
    guard parts.count == 2 else { return nil }
    return sign * (parts[0] * 3600 + parts[1] * 60)
}

private func utcCalendar() -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(secondsFromGMT: 0)!
    return cal
}

private func hhmmStringFromDate(_ d: Date, calendar: Calendar) -> String {
    let comps = calendar.dateComponents([.hour, .minute], from: d)
    return String(format: "%02d:%02d", comps.hour ?? 0, comps.minute ?? 0)
}

private func ymdStringFromDate(_ d: Date, calendar: Calendar) -> String {
    let comps = calendar.dateComponents([.year, .month, .day], from: d)
    return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
}
