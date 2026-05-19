import SwiftUI
import SwiftData

enum Tab: String, CaseIterable {
    case today = "Today"
    case program = "Program"
    case log = "Morning Log"
    case progress = "Progress"
    case tools = "Tools"

    var icon: String {
        switch self {
        case .today:    return "moon.stars.fill"
        case .program:  return "book.closed.fill"
        case .log:      return "sun.horizon.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .tools:    return "wrench.and.screwdriver"
        }
    }
}

struct ContentView: View {
    @Query private var logs: [SleepLog]
    @State private var selection: Tab? = .today
    @State private var showingSettings = false

    private var unwrappedSelection: Binding<Tab> {
        Binding(
            get: { selection ?? .today },
            set: { selection = $0 }
        )
    }

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
                .preferredColorScheme(.dark)
                .tint(.warmAmber)
        } else {
            sidebarView
                .preferredColorScheme(.dark)
                .tint(.warmAmber)
        }
        #else
        sidebarView
            .preferredColorScheme(.dark)
            .tint(.warmAmber)
        #endif
    }

    // MARK: - iPhone (compact): bottom tab bar

    private var tabsView: some View {
        TabView(selection: unwrappedSelection) {
            ForEach(Tab.allCases, id: \.self) { tab in
                NavigationStack {
                    tabContent(tab)
                        .navigationTitle(tab == .today ? "" : tab.rawValue)
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(tab == .today ? .inline : .large)
                        .toolbarBackground(Color.bgApp, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
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
                                .foregroundStyle(selection == tab ? Color.warmAmberStrong : Color.fg2)
                            if tab == .log && !hasToday {
                                Spacer()
                                Circle()
                                    .fill(Color.warmAmber)
                                    .frame(width: 6, height: 6)
                            }
                        }
                    } icon: {
                        Image(systemName: tab.icon)
                            .foregroundStyle(selection == tab ? Color.warmAmber : Color.fg3)
                    }
                    .tag(tab)
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgApp.ignoresSafeArea())
            .navigationTitle("CBT-I")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
            #if os(iOS)
            .toolbar { settingsToolbarItem }
            .toolbarBackground(Color.bgApp, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
        } detail: {
            tabContent(selection ?? .today)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.bgApp.ignoresSafeArea())
                #if os(iOS)
                .toolbarBackground(Color.bgApp, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                #endif
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
        case .today:    TodayTab(selectedTab: $selection)
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
                    .foregroundStyle(Color.fg2)
            }
            .accessibilityLabel("Settings")
        }
    }

    private var settingsSheet: some View {
        NavigationStack {
            List {
                NavigationLink {
                    iCloudSyncPane()
                        .padding(20)
                        .navigationTitle("iCloud sync")
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                } label: {
                    Label("iCloud sync", systemImage: "icloud")
                }

                NavigationLink {
                    WhoopSettingsPane()
                        .padding(20)
                        .navigationTitle("Whoop")
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                } label: {
                    Label("Whoop integration", systemImage: "waveform.path.ecg")
                }
            }
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
