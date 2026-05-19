import SwiftUI
import SwiftData
import CloudKit

struct iCloudSyncPane: View {
    @Query private var logs: [SleepLog]
    @State private var accountStatus: CKAccountStatus = .couldNotDetermine
    @State private var checking = false
    @State private var lastChecked: Date? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("iCloud sync")
                .font(.title3)
                .fontWeight(.semibold)

            statusRow

            statsRow

            Divider().padding(.top, 8)

            VStack(alignment: .leading, spacing: 6) {
                Text("How this works")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Your sleep logs sync automatically across every Apple device signed into the same iCloud account — iPhone, iPad, Mac. Changes appear within seconds when devices are online.")
                Text("Storage uses your iCloud private database, not iCloud Drive — it doesn't count against the visible quota and isn't shared with anyone else.")
                    .padding(.top, 2)
                Text("If iCloud is signed out or sync is disabled in iOS Settings → Apple Account → iCloud, this app stores data locally only.")
                    .padding(.top, 2)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()
        }
        .onAppear { checkStatus() }
        .onReceive(NotificationCenter.default.publisher(for: .CKAccountChanged)) { _ in
            checkStatus()
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 9, height: 9)
            Text(statusLabel)
                .font(.callout)
            if checking {
                ProgressView().controlSize(.small).padding(.leading, 4)
            }
            Spacer()
            Button {
                checkStatus()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Re-check iCloud account status")
        }
    }

    private var statsRow: some View {
        HStack(spacing: 24) {
            stat("Logs on this device", "\(logs.count)")
            if let date = lastChecked {
                stat("Status checked", relativeTime(date))
            }
            Spacer()
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.callout).fontWeight(.medium)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var statusColor: Color {
        switch accountStatus {
        case .available: return .green
        case .couldNotDetermine: return .orange
        case .restricted, .noAccount, .temporarilyUnavailable: return .red
        @unknown default: return .secondary
        }
    }

    private var statusLabel: String {
        switch accountStatus {
        case .available: return "Connected — data syncs across your Apple devices"
        case .couldNotDetermine: return "Checking iCloud status…"
        case .noAccount: return "Not signed in to iCloud — data is local only"
        case .restricted: return "iCloud restricted (parental controls or MDM)"
        case .temporarilyUnavailable: return "iCloud temporarily unavailable"
        @unknown default: return "Unknown iCloud status"
        }
    }

    private func checkStatus() {
        checking = true
        CKContainer(identifier: "iCloud.com.montysharma.cbti").accountStatus { status, _ in
            DispatchQueue.main.async {
                accountStatus = status
                lastChecked = Date()
                checking = false
            }
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }
}
