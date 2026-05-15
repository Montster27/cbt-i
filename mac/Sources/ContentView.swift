import SwiftUI
import SwiftData

enum Tab: String, CaseIterable {
    case program = "Program"
    case log = "Morning Log"
    case progress = "Progress"
    case tools = "Tools"

    var icon: String {
        switch self {
        case .program: return "calendar"
        case .log: return "pencil.and.list.clipboard"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .tools: return "wrench.and.screwdriver"
        }
    }
}

struct ContentView: View {
    @Query private var logs: [SleepLog]
    @State private var selection: Tab? = .program
    @State private var showingSettings = false

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var hSizeClass
    #endif

    private var hasToday: Bool {
        logs.contains(where: { $0.date == todayISO() })
    }

    var body: some View {
        #if os(iOS)
        if hSizeClass == .compact {
            tabsView
        } else {
            sidebarView
        }
        #else
        sidebarView
        #endif
    }

    // MARK: - iPhone (compact): bottom tab bar

    private var tabsView: some View {
        TabView(selection: $selection) {
            ForEach(Tab.allCases, id: \.self) { tab in
                NavigationStack {
                    tabContent(tab)
                        .navigationTitle(tab.rawValue)
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                        .toolbar { settingsToolbarItem }
                }
                .tabItem {
                    Label(tab.rawValue, systemImage: tab.icon)
                }
                .badge(tab == .log && !hasToday ? "•" : nil)
                .tag(tab)
            }
        }
        .sheet(isPresented: $showingSettings) {
            settingsSheet
        }
    }

    // MARK: - iPad + Mac: sidebar split view

    private var sidebarView: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Label {
                        HStack {
                            Text(tab.rawValue)
                            if tab == .log && !hasToday {
                                Spacer()
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 6, height: 6)
                            }
                        }
                    } icon: {
                        Image(systemName: tab.icon)
                    }
                    .tag(tab)
                }
            }
            .navigationTitle("CBT-I")
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
            #if os(iOS)
            .toolbar { settingsToolbarItem }
            #endif
        } detail: {
            tabContent(selection ?? .program)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                #if os(macOS)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 1) {
                            Text("6-week sleep restructuring")
                                .font(.headline)
                            Text("Fixed wake 5:45 AM · Focus on racing thoughts")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                #endif
        }
        #if os(iOS)
        .sheet(isPresented: $showingSettings) {
            settingsSheet
        }
        #endif
    }

    // MARK: - shared

    @ViewBuilder
    private func tabContent(_ tab: Tab) -> some View {
        switch tab {
        case .program:  ProgramTab()
        case .log:      LogTab()
        case .progress: ProgressTab()
        case .tools:    ToolsTab()
        }
    }

    @ToolbarContentBuilder
    private var settingsToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gear")
            }
            .accessibilityLabel("Settings")
        }
    }

    private var settingsSheet: some View {
        NavigationStack {
            WhoopSettingsPane()
                .padding(20)
                .navigationTitle("Settings")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { showingSettings = false }
                    }
                }
        }
    }
}
