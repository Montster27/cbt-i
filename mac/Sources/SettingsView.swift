import SwiftUI

#if os(macOS)
/// macOS-only: wrapped in the App's `Settings { ... }` scene. ⌘, opens it.
/// On iOS, `ContentView` presents a List of settings panes in a sheet.
struct SettingsView: View {
    var body: some View {
        TabView {
            iCloudSyncPane()
                .tabItem { Label("iCloud", systemImage: "icloud") }
                .padding(20)
                .frame(width: 520, height: 360)

            WhoopSettingsPane()
                .tabItem { Label("Whoop", systemImage: "waveform.path.ecg") }
                .padding(20)
                .frame(width: 520, height: 360)
        }
    }
}
#endif

struct WhoopSettingsPane: View {
    @EnvironmentObject var whoop: WhoopStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Whoop integration")
                .font(.title3)
                .fontWeight(.semibold)

            statusRow

            actionRow

            if let err = whoop.lastError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }

            Divider().padding(.top, 8)

            VStack(alignment: .leading, spacing: 6) {
                Text("How this works")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Sign-in goes through a Whoop authorization page in your browser, then a secure backend exchanges the code for an access token. No credentials live on this device — only the access and refresh tokens issued to you by Whoop.")
                Text("Connect once per device. Tokens sync across your Apple devices via iCloud Keychain.")
                    .padding(.top, 2)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 9, height: 9)
            Text(statusLabel).font(.callout)
            Spacer()
        }
    }

    private var statusColor: Color {
        switch whoop.status {
        case .connected: return .green
        case .connecting: return .orange
        case .disconnected: return .secondary
        }
    }

    private var statusLabel: String {
        switch whoop.status {
        case .connected: return "Connected to Whoop"
        case .connecting: return "Opening Whoop sign-in…"
        case .disconnected: return "Not connected"
        }
    }

    private var actionRow: some View {
        HStack {
            switch whoop.status {
            case .disconnected:
                Button("Connect to Whoop") {
                    Task { await whoop.connect() }
                }
                .keyboardShortcut(.defaultAction)
            case .connecting:
                ProgressView().controlSize(.small)
                Text("Awaiting Whoop sign-in…").font(.caption).foregroundStyle(.secondary)
            case .connected:
                Button("Disconnect") { whoop.disconnect() }
            }
            Spacer()
        }
    }
}
