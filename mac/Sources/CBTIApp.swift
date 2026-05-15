import SwiftUI
import SwiftData

@main
struct CBTIApp: App {
    @StateObject private var whoop = WhoopStore()
    private let modelContainer: ModelContainer

    init() {
        do {
            let config = ModelConfiguration(
                schema: Schema([SleepLog.self]),
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            modelContainer = try ModelContainer(for: SleepLog.self, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        let container = modelContainer
        Task { @MainActor in
            DataMigration.migrateFromUserDefaultsIfNeeded(container: container)
        }
    }

    var body: some Scene {
        WindowGroup("CBT-I") {
            ContentView()
                .environmentObject(whoop)
                #if os(macOS)
                .frame(minWidth: 720, minHeight: 600)
                #endif
        }
        .modelContainer(modelContainer)
        #if os(macOS)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        #endif

        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(whoop)
        }
        #endif
    }
}
