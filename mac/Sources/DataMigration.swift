import Foundation
import SwiftData

enum DataMigration {
    private static let legacyLogsKey = "cbti.logs"
    private static let legacyStartKey = "cbti.start"
    private static let migratedKey = "cbti.migration.v1.done"

    /// Reads the pre-SwiftData UserDefaults JSON (if present) and inserts each entry
    /// as a SwiftData record. Idempotent — runs at most once per device.
    @MainActor
    static func migrateFromUserDefaultsIfNeeded(container: ModelContainer) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: migratedKey) else { return }

        guard let data = defaults.data(forKey: legacyLogsKey) else {
            defaults.set(true, forKey: migratedKey)
            return
        }

        do {
            let decoded = try JSONDecoder().decode([LegacySleepLog].self, from: data)
            let context = container.mainContext

            let existing = (try? context.fetch(FetchDescriptor<SleepLog>())) ?? []
            let existingDates = Set(existing.map(\.date))

            var inserted = 0
            for log in decoded where !existingDates.contains(log.date) {
                let model = SleepLog(
                    date: log.date,
                    inBed: log.inBed,
                    lightsOut: log.lightsOut,
                    latency: log.latency,
                    wakeCount: log.wakeCount,
                    wakeMin: log.wakeMin,
                    finalWake: log.finalWake,
                    outBed: log.outBed,
                    quality: log.quality,
                    mood: log.mood
                )
                context.insert(model)
                inserted += 1
            }
            try context.save()
            defaults.set(true, forKey: migratedKey)
            NSLog("[CBT-I] Migrated %d legacy log(s) into SwiftData.", inserted)
        } catch {
            NSLog("[CBT-I] Migration failed: %@", error.localizedDescription)
        }
    }
}

private struct LegacySleepLog: Decodable {
    let date: String
    let inBed: String
    let lightsOut: String
    let latency: Int
    let wakeCount: Int
    let wakeMin: Int
    let finalWake: String
    let outBed: String
    let quality: Int
    let mood: Int
}
