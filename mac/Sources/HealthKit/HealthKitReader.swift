import Foundation
import HealthKit

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationFailed(Error)
    case queryFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable: return "HealthKit isn't available on this device."
        case .authorizationFailed(let err): return "HealthKit authorization failed: \(err.localizedDescription)"
        case .queryFailed(let err): return "HealthKit query failed: \(err.localizedDescription)"
        }
    }
}

/// Reads the user's most recent overnight sleep from HealthKit and returns it
/// as a draft. Apple Watch is the primary contributor of sleep stage samples on
/// modern devices; older devices may only produce `.inBed` and `.asleepUnspecified`.
@MainActor
final class HealthKitReader {
    private let store = HKHealthStore()

    private var sleepType: HKCategoryType {
        HKCategoryType(.sleepAnalysis)
    }
    private var hrvType: HKQuantityType {
        HKQuantityType(.heartRateVariabilitySDNN)
    }
    private var rhrType: HKQuantityType {
        HKQuantityType(.restingHeartRate)
    }

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Triggers the system permission sheet on first call. Apple's privacy model
    /// hides per-type denial from the app — empty queries are the signal of denial.
    func requestAuthorization() async throws {
        guard isAvailable else { throw HealthKitError.notAvailable }
        let readSet: Set<HKObjectType> = [sleepType, hrvType, rhrType]
        do {
            try await store.requestAuthorization(toShare: [], read: readSet)
        } catch {
            throw HealthKitError.authorizationFailed(error)
        }
    }

    /// Pulls the most recent overnight sleep session from the past `lookbackHours` and
    /// returns a draft. Latency, wake count, and wake minutes are derived from sample
    /// timing. Returns nil if no relevant samples are found.
    func fetchLatestSleep(lookbackHours: Int = 36) async throws -> SleepLogDraft? {
        guard isAvailable else { return nil }
        try await requestAuthorization()

        let end = Date()
        let start = end.addingTimeInterval(-TimeInterval(lookbackHours) * 3600)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let samples = try await querySamples(type: sleepType, predicate: predicate)

        let categorySamples = samples.compactMap { $0 as? HKCategorySample }
        guard !categorySamples.isEmpty else { return nil }

        // Group into sessions by gaps > 2h; pick the most recent session.
        let session = mostRecentSession(in: categorySamples)
        guard !session.isEmpty else { return nil }

        let analysis = analyze(samples: session)
        guard analysis.tib > 0 else { return nil }

        // HRV and RHR — average over the sleep window, fallback to most recent reading.
        let hrv = try? await averageQuantity(type: hrvType, start: analysis.inBedStart, end: analysis.outBedEnd, unit: HKUnit.secondUnit(with: .milli))
        let rhr = try? await averageQuantity(type: rhrType, start: analysis.inBedStart, end: analysis.outBedEnd, unit: HKUnit.count().unitDivided(by: HKUnit.minute()))

        let hypno = buildHypnogram(from: session)
        let hasStages = analysis.remMin + analysis.deepMin + analysis.lightMin > 0

        return SleepLogDraft(
            date: ymdLocal(analysis.outBedEnd),
            inBed: hhmmLocal(analysis.inBedStart),
            lightsOut: hhmmLocal(analysis.inBedStart),
            latency: analysis.latencyMin,
            wakeCount: analysis.wakeCount,
            wakeMin: analysis.wakeMin,
            finalWake: hhmmLocal(analysis.outBedEnd),
            outBed: hhmmLocal(analysis.outBedEnd),
            quality: 5,
            mood: 5,
            whoopStrain: nil,
            whoopRecovery: nil,
            whoopHRV: hrv,
            whoopRHR: rhr.map { Int($0.rounded()) },
            remMin: hasStages ? analysis.remMin : nil,
            deepMin: hasStages ? analysis.deepMin : nil,
            lightMin: hasStages ? analysis.lightMin : nil,
            awakeMin: hasStages ? analysis.wakeMin : nil,
            sleepCycles: nil,
            hypnogramJSON: hypno.isEmpty ? nil : hypno.jsonString
        )
    }

    /// Builds a normalized event sequence ready to feed the hypnogram view.
    /// Adjacent same-stage samples are merged so the view doesn't render hairline seams.
    private func buildHypnogram(from samples: [HKCategorySample]) -> [HypnogramEvent] {
        let staged: [HypnogramEvent] = samples
            .sorted { $0.startDate < $1.startDate }
            .compactMap { sample in
                guard let stage = stage(for: sample.value) else { return nil }
                return HypnogramEvent(stage: stage, start: sample.startDate, end: sample.endDate)
            }
        guard !staged.isEmpty else { return [] }

        var merged: [HypnogramEvent] = []
        for ev in staged {
            if let last = merged.last, last.stage == ev.stage, ev.start <= last.end.addingTimeInterval(60) {
                merged[merged.count - 1] = HypnogramEvent(stage: last.stage, start: last.start, end: max(last.end, ev.end))
            } else {
                merged.append(ev)
            }
        }
        return merged
    }

    private func stage(for value: Int) -> SleepStage? {
        switch value {
        case HKCategoryValueSleepAnalysis.awake.rawValue:
            return .awake
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
            return .rem
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
            return .deep
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
             HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
            return .light
        default:
            return nil  // inBed and others — bracketing only, not stage data.
        }
    }

    // MARK: - sample analysis

    private struct SessionAnalysis {
        let inBedStart: Date
        let outBedEnd: Date
        let tib: Int          // minutes
        let latencyMin: Int
        let wakeCount: Int
        let wakeMin: Int
        let remMin: Int
        let deepMin: Int
        let lightMin: Int
    }

    private func mostRecentSession(in samples: [HKCategorySample]) -> [HKCategorySample] {
        let sorted = samples.sorted { $0.startDate < $1.startDate }
        var sessions: [[HKCategorySample]] = []
        var current: [HKCategorySample] = []
        var lastEnd: Date?
        for sample in sorted {
            if let lastEnd, sample.startDate.timeIntervalSince(lastEnd) > 2 * 3600 {
                if !current.isEmpty { sessions.append(current) }
                current = []
            }
            current.append(sample)
            lastEnd = max(lastEnd ?? sample.endDate, sample.endDate)
        }
        if !current.isEmpty { sessions.append(current) }
        return sessions.last ?? []
    }

    private func analyze(samples: [HKCategorySample]) -> SessionAnalysis {
        let inBedSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue }
        let asleepSamples = samples.filter { isAsleepValue($0.value) }
        let awakeSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.awake.rawValue }

        // In-bed range — fall back to overall sample range if no .inBed samples.
        let inBedStart = inBedSamples.map(\.startDate).min() ?? samples.map(\.startDate).min()!
        let outBedEnd = inBedSamples.map(\.endDate).max() ?? samples.map(\.endDate).max()!
        let tibSeconds = outBedEnd.timeIntervalSince(inBedStart)
        let tib = max(0, Int(tibSeconds / 60))

        // Latency — from in-bed start to first asleep sample.
        let firstAsleep = asleepSamples.map(\.startDate).min()
        let latencyMin: Int = {
            if let firstAsleep, firstAsleep > inBedStart {
                return Int(firstAsleep.timeIntervalSince(inBedStart) / 60)
            }
            return 0
        }()

        // Wake events — only count those that happen between first and last asleep moments.
        let lastAsleep = asleepSamples.map(\.endDate).max() ?? outBedEnd
        let withinSleep = awakeSamples.filter { $0.startDate >= (firstAsleep ?? inBedStart) && $0.endDate <= lastAsleep }
        let mergedWake = mergeOverlapping(withinSleep.map { ($0.startDate, $0.endDate) })
        let wakeMin = mergedWake.reduce(0) { $0 + Int($1.1.timeIntervalSince($1.0) / 60) }
        let wakeCount = mergedWake.count

        // Per-stage totals. Apple Watch is the typical source; older devices may only
        // emit `.asleepUnspecified`, which we treat as light.
        func stageMinutes(_ rawValue: Int) -> Int {
            let merged = mergeOverlapping(
                samples
                    .filter { $0.value == rawValue }
                    .map { ($0.startDate, $0.endDate) }
            )
            return merged.reduce(0) { $0 + Int($1.1.timeIntervalSince($1.0) / 60) }
        }
        let remMin = stageMinutes(HKCategoryValueSleepAnalysis.asleepREM.rawValue)
        let deepMin = stageMinutes(HKCategoryValueSleepAnalysis.asleepDeep.rawValue)
        let lightMin =
            stageMinutes(HKCategoryValueSleepAnalysis.asleepCore.rawValue) +
            stageMinutes(HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue)

        return SessionAnalysis(
            inBedStart: inBedStart,
            outBedEnd: outBedEnd,
            tib: tib,
            latencyMin: latencyMin,
            wakeCount: wakeCount,
            wakeMin: wakeMin,
            remMin: remMin,
            deepMin: deepMin,
            lightMin: lightMin
        )
    }

    private func isAsleepValue(_ value: Int) -> Bool {
        let core = HKCategoryValueSleepAnalysis.asleepCore.rawValue
        let deep = HKCategoryValueSleepAnalysis.asleepDeep.rawValue
        let rem = HKCategoryValueSleepAnalysis.asleepREM.rawValue
        let unspecified = HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
        return value == core || value == deep || value == rem || value == unspecified
    }

    private func mergeOverlapping(_ ranges: [(Date, Date)]) -> [(Date, Date)] {
        let sorted = ranges.sorted { $0.0 < $1.0 }
        var merged: [(Date, Date)] = []
        for r in sorted {
            if var last = merged.last, r.0 <= last.1 {
                last.1 = max(last.1, r.1)
                merged[merged.count - 1] = last
            } else {
                merged.append(r)
            }
        }
        return merged
    }

    // MARK: - query helpers

    private func querySamples(type: HKSampleType, predicate: NSPredicate) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            let q = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, results, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                } else {
                    continuation.resume(returning: results ?? [])
                }
            }
            store.execute(q)
        }
    }

    private func averageQuantity(type: HKQuantityType, start: Date, end: Date, unit: HKUnit) async throws -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let samples = try await querySamples(type: type, predicate: predicate)
        let values = samples.compactMap { ($0 as? HKQuantitySample)?.quantity.doubleValue(for: unit) }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    // MARK: - formatting

    private func hhmmLocal(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }

    private func ymdLocal(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }
}
