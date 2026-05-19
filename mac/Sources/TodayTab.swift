import SwiftUI
import SwiftData

struct TodayTab: View {
    @Query(sort: \SleepLog.date) private var logs: [SleepLog]
    @Binding var selectedTab: Tab?

    private var currentWeek: Int { weekNumber(from: logs) }
    private var hasLoggedToday: Bool { logs.contains { $0.date == todayISO() } }
    private var lastLog: SleepLog? { logs.last }
    private var streak: Int {
        guard !logs.isEmpty else { return 0 }
        let set = Set(logs.map { $0.date })
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        var count = 0
        var d = Date()
        while true {
            let key = f.string(from: d)
            if set.contains(key) {
                count += 1
                d = Calendar.current.date(byAdding: .day, value: -1, to: d) ?? d
            } else {
                break
            }
        }
        return count
    }

    private var week: WeekContent { WEEKS[min(currentWeek - 1, WEEKS.count - 1)] }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 4 { return "Good night" }
        if h < 12 { return "Good morning" }
        if h < 18 { return "Good afternoon" }
        return "Good evening"
    }

    private var dayName: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f.string(from: Date())
    }

    private var tonightBedtimeShort: (String, String) {
        // pull "11:45 PM" out of the week's bedtime field
        let pattern = #"(\d{1,2}:\d{2})\s*([AP]M)"#
        if let r = week.bedtime.range(of: pattern, options: .regularExpression) {
            let match = String(week.bedtime[r])
            let parts = match.components(separatedBy: " ")
            if parts.count == 2 { return (parts[0], parts[1]) }
        }
        return ("11:45", "PM")
    }

    private var windDownMinutes: Int? {
        let (t, ampm) = tonightBedtimeShort
        let parts = t.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        var h = parts[0]; let m = parts[1]
        if ampm == "PM" && h != 12 { h += 12 }
        if ampm == "AM" && h == 12 { h = 0 }
        let target = h * 60 + m - 15
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let cur = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        var diff = target - cur
        if diff < 0 { diff += 1440 }
        return diff
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                greetingHeader
                tonightHero
                statRow
                practiceCard
                if !hasLoggedToday { logCTA }
                quickToolsRow
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 36)
        }
        .scrollContentBackground(.hidden)
        .appBackground(withStars: true)
    }

    // MARK: - greeting

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(dayName) · Week \(currentWeek)").kicker()
            Text("\(greeting).")
                .font(.serifDisplay)
                .foregroundStyle(Color.fg1)
            Text("\u{201C}Sleep is set up, not chased.\u{201D}")
                .font(.system(size: 14, design: .serif))
                .italic()
                .foregroundStyle(Color.fg3)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - hero

    private var tonightHero: some View {
        ZStack(alignment: .topLeading) {
            // background gradient
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.skyAccent.opacity(0.18), Color(red: 0x16/255, green: 0x20/255, blue: 0x3A/255).opacity(0.4)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            // top-right glow
            Circle()
                .fill(RadialGradient(colors: [Color.warmAmber.opacity(0.18), .clear],
                                     center: .center, startRadius: 0, endRadius: 120))
                .frame(width: 220, height: 220)
                .offset(x: 180, y: -90)
                .blur(radius: 8)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(alignment: .leading, spacing: 0) {
                Text("TONIGHT'S WINDOW")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Color(red: 0x99/255, green: 0xC1/255, blue: 0xEA/255))
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(tonightBedtimeShort.0)
                        .font(.system(size: 44, weight: .semibold, design: .default))
                        .foregroundStyle(Color.fg1)
                        .monospacedDigit()
                    Text(tonightBedtimeShort.1)
                        .font(.system(size: 18))
                        .foregroundStyle(Color.fg3)
                }
                .padding(.top, 8)

                if let wd = windDownMinutes, wd < 240 {
                    (
                        Text("Wind-down begins in ")
                        + Text("\(wd) min").foregroundColor(.warmAmber).fontWeight(.semibold)
                        + Text(" · wake 5:45 AM")
                    )
                    .font(.system(size: 13))
                    .foregroundStyle(Color.fg3)
                    .padding(.top, 2)
                } else {
                    Text("Wake at 5:45 AM · \(week.theme)")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fg3)
                        .padding(.top, 2)
                }

                Button {
                    selectedTab = .tools
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.stars.fill")
                        Text("Start wind-down").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.warmAmber)
                    .foregroundStyle(Color(red: 0x06/255, green: 0x09/255, blue: 0x12/255))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.top, 16)
            }
            .padding(22)
        }
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.skyAccent.opacity(0.22), lineWidth: 1)
        )
    }

    // MARK: - stat row

    private var statRow: some View {
        HStack(spacing: 10) {
            lastNightCard
            VStack(alignment: .leading, spacing: 4) {
                Text("STREAK").kicker()
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.warmAmber)
                    Text("\(streak)")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.fg1)
                        .monospacedDigit()
                }
                Text("nights logged").font(.system(size: 11)).foregroundStyle(Color.fg4)
            }
            .warmCard(padding: 14)
        }
    }

    @ViewBuilder
    private var lastNightCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LAST NIGHT").kicker()
            if let last = lastLog {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(last.se)")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.seSwiftUIColor(last.se))
                        .monospacedDigit()
                    Text("%").font(.system(size: 16)).foregroundStyle(Color.fg4)
                }
                Text("\(String(format: "%.1f", last.hoursDecimal))h sleep · SE")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fg4)

                if last.hasStageData {
                    StageMiniBar(
                        remMin: last.remMin ?? 0,
                        deepMin: last.deepMin ?? 0,
                        lightMin: last.lightMin ?? 0,
                        awakeMin: last.awakeMin ?? 0
                    )
                    .padding(.top, 4)
                    stageChipRow(for: last)
                }
            } else {
                Text("—")
                    .font(.serifH2)
                    .foregroundStyle(Color.fg3)
                Text("Log to begin").font(.system(size: 11)).foregroundStyle(Color.fg4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard(padding: 14)
    }

    /// Inline legend: REM and Deep minutes — the two stages users care about. Light/Awake
    /// are visible in the StageMiniBar but don't need numbers in the compact card.
    private func stageChipRow(for log: SleepLog) -> some View {
        HStack(spacing: 10) {
            stageChip(stage: .rem, minutes: log.remMin ?? 0)
            stageChip(stage: .deep, minutes: log.deepMin ?? 0)
        }
        .padding(.top, 2)
    }

    private func stageChip(stage: SleepStage, minutes: Int) -> some View {
        HStack(spacing: 4) {
            Circle().fill(stage.color).frame(width: 6, height: 6)
            Text(stage.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.fg3)
            Text(stageShort(minutes))
                .font(.system(size: 10, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Color.fg1)
        }
    }

    private func stageShort(_ mins: Int) -> String {
        let h = mins / 60
        let m = mins % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h\(m)m"
    }

    // MARK: - practice card

    private var practiceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TONIGHT'S PRACTICE").kicker()
                Spacer()
                Button {
                    selectedTab = .program
                } label: {
                    Text("See week →")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.warmAmber)
                }
                .buttonStyle(.plain)
            }
            ForEach(Array(week.rules.prefix(3).enumerated()), id: \.offset) { i, rule in
                if i > 0 {
                    Divider().background(Color.borderSoft)
                }
                HStack(alignment: .center, spacing: 12) {
                    Text("\(i + 1)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.warmAmberStrong)
                        .frame(width: 32, height: 32)
                        .background(Color.warmAmberSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Text(rule)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fg2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
            }
        }
        .warmCard()
    }

    // MARK: - log CTA

    private var logCTA: some View {
        Button {
            selectedTab = .log
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.warmAmber)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Log today's night")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 0xEF/255, green: 0xD3/255, blue: 0xB4/255))
                    Text("Fill in within 30 min of waking")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fg4)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.warmAmber)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.warmAmberSoft)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.warmAmber.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - quick tools

    private var quickToolsRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("QUICK TOOLS").kicker()
            HStack(spacing: 10) {
                quickTool("Breathing", system: "wind", color: .skyAccent)
                quickTool("Body scan", system: "sparkles", color: .warmAmber)
                quickTool("Worry park", system: "square.and.pencil", color: .good400)
            }
        }
    }

    private func quickTool(_ label: String, system: String, color: Color) -> some View {
        Button {
            selectedTab = .tools
        } label: {
            VStack(spacing: 6) {
                Image(systemName: system)
                    .font(.system(size: 22))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.fg2)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.bgSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.borderSoft, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
