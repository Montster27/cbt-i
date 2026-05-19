import SwiftUI

// MARK: - Warm nighttime palette

extension Color {
    // Surfaces
    static let bgApp      = Color(red: 0x1A/255, green: 0x14/255, blue: 0x10/255)
    static let bgSurface  = Color(red: 0x22/255, green: 0x1A/255, blue: 0x14/255)
    static let bgElev     = Color(red: 0x2A/255, green: 0x20/255, blue: 0x1A/255)
    static let bgElev2    = Color(red: 0x31/255, green: 0x26/255, blue: 0x20/255)
    static let bgChip     = Color(red: 0x3A/255, green: 0x2E/255, blue: 0x26/255)

    // Foreground
    static let fg1        = Color(red: 0xF5/255, green: 0xEC/255, blue: 0xE0/255)
    static let fg2        = Color(red: 0xD9/255, green: 0xC9/255, blue: 0xB3/255)
    static let fg3        = Color(red: 0xA8/255, green: 0x95/255, blue: 0x80/255)
    static let fg4        = Color(red: 0x7D/255, green: 0x6C/255, blue: 0x5A/255)

    // Accent (warm amber — locked direction)
    static let warmAmber       = Color(red: 0xE5/255, green: 0xBC/255, blue: 0x92/255)
    static let warmAmberStrong = Color(red: 0xF0/255, green: 0xD2/255, blue: 0xB0/255)
    static let warmAmberSoft   = Color(red: 0xE5/255, green: 0xBC/255, blue: 0x92/255).opacity(0.14)

    // Sky / good / warn / crit
    static let skyAccent       = Color(red: 0x79/255, green: 0xAB/255, blue: 0xE0/255)
    static let skyAccentDeep   = Color(red: 0x5A/255, green: 0x92/255, blue: 0xD0/255)
    static let good400         = Color(red: 0x7A/255, green: 0xB7/255, blue: 0x8B/255)
    static let warn400         = Color(red: 0xD9/255, green: 0xB3/255, blue: 0x5A/255)
    static let crit400         = Color(red: 0xD9/255, green: 0x7C/255, blue: 0x7C/255)

    // Borders
    static let borderSoft    = Color(red: 0xF5/255, green: 0xDC/255, blue: 0xBC/255).opacity(0.06)
    static let borderDefault = Color(red: 0xF5/255, green: 0xDC/255, blue: 0xBC/255).opacity(0.11)
    static let borderStrong  = Color(red: 0xF5/255, green: 0xDC/255, blue: 0xBC/255).opacity(0.18)

    static func seSwiftUIColor(_ se: Int) -> Color {
        if se >= 85 { return .good400 }
        if se >= 75 { return .warn400 }
        return .crit400
    }
}

// MARK: - Font helpers

extension Font {
    static func serif(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static let serifDisplay = Font.system(size: 34, weight: .medium, design: .serif)
    static let serifH1      = Font.system(size: 26, weight: .medium, design: .serif)
    static let serifH2      = Font.system(size: 20, weight: .medium, design: .serif)
}

// MARK: - Reusable view modifiers

struct Kicker: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(Color.fg4)
    }
}

struct WarmCardStyle: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.bgSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.borderSoft, lineWidth: 1)
                    )
            )
    }
}

struct WarmElevCardStyle: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.bgElev)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.borderSoft, lineWidth: 1)
                    )
            )
    }
}

struct AppBackground: ViewModifier {
    var withStars: Bool = false
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Color.bgApp.ignoresSafeArea()
                    if withStars {
                        RadialGradient(
                            colors: [Color.skyAccent.opacity(0.18), .clear],
                            center: .top, startRadius: 20, endRadius: 380
                        ).ignoresSafeArea()
                        StarField(count: 50).ignoresSafeArea()
                    }
                }
            )
    }
}

extension View {
    func kicker() -> some View { modifier(Kicker()) }
    func warmCard(padding: CGFloat = 16) -> some View { modifier(WarmCardStyle(padding: padding)) }
    func warmElevCard(padding: CGFloat = 16) -> some View { modifier(WarmElevCardStyle(padding: padding)) }
    func appBackground(withStars: Bool = false) -> some View { modifier(AppBackground(withStars: withStars)) }
}

// MARK: - Chip

struct WarmChip: View {
    let text: String
    var systemImage: String? = nil
    var tint: ChipTint = .neutral
    enum ChipTint { case neutral, accent, good }

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 10, weight: .medium))
            }
            Text(text).font(.system(size: 11, weight: .medium)).tracking(0.1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(bgColor))
        .overlay(Capsule().strokeBorder(borderColor, lineWidth: 1))
        .foregroundStyle(textColor)
    }

    private var bgColor: Color {
        switch tint {
        case .neutral: return .bgChip
        case .accent:  return .warmAmberSoft
        case .good:    return Color.good400.opacity(0.12)
        }
    }
    private var borderColor: Color {
        switch tint {
        case .neutral: return .borderSoft
        case .accent:  return Color.warmAmber.opacity(0.22)
        case .good:    return Color.good400.opacity(0.22)
        }
    }
    private var textColor: Color {
        switch tint {
        case .neutral: return .fg2
        case .accent:  return .warmAmberStrong
        case .good:    return .good400
        }
    }
}

// MARK: - Progress ring

struct ProgressRing<Content: View>: View {
    var value: Double
    var max: Double = 100
    var size: CGFloat = 110
    var stroke: CGFloat = 10
    var color: Color
    @ViewBuilder var label: () -> Content

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: stroke)
            Circle()
                .trim(from: 0, to: CGFloat(min(1, value / max)))
                .stroke(color, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.7), value: value)
            label()
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Star field

fileprivate struct StarShape: Identifiable {
    let id: Int
    let x: Double
    let y: Double
    let size: Double
    let delay: Double
    let duration: Double
    let isWarm: Bool
}

struct StarField: View {
    var count: Int = 50
    var opacity: Double = 0.7

    private var stars: [StarShape] {
        (0..<count).map { i in
            func rng(_ k: Int) -> Double {
                let v = abs(sin(Double(42 * 9301 + k * 49297)) * 233280)
                return v - floor(v)
            }
            return StarShape(
                id: i,
                x: rng(i) * 100,
                y: rng(i + 999) * 100,
                size: 1.0 + rng(i + 333) * 1.6,
                delay: rng(i + 77) * 6,
                duration: 3 + rng(i + 222) * 6,
                isWarm: i % 7 == 0
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(stars) { s in
                TwinkleStar(star: s)
                    .position(x: geo.size.width * s.x / 100,
                              y: geo.size.height * s.y / 100)
            }
        }
        .opacity(opacity)
        .allowsHitTesting(false)
    }
}

private struct TwinkleStar: View {
    let star: StarShape
    @State private var phase = false

    var body: some View {
        Circle()
            .fill(star.isWarm
                  ? Color(red: 0xE7/255, green: 0xBF/255, blue: 0x99/255)
                  : Color(red: 0xEB/255, green: 0xEE/255, blue: 0xF7/255))
            .frame(width: star.size, height: star.size)
            .opacity(phase ? 1.0 : 0.25)
            .animation(.easeInOut(duration: star.duration).repeatForever(autoreverses: true).delay(star.delay),
                       value: phase)
            .onAppear { phase = true }
    }
}

// MARK: - Sleep block visualizer

struct SleepBlockViz: View {
    var tib: Int           // minutes
    var latency: Int
    var wakeMin: Int
    var inBed: String
    var outBed: String

    private var segments: [(width: Double, color: Color)] {
        guard tib > 0 else { return [] }
        let tibD = Double(tib)
        let half = max(0, (tib - latency - wakeMin)) / 2
        return [
            (Double(latency) / tibD,    Color(red: 0xDB/255, green: 0xA8/255, blue: 0x7A/255).opacity(0.5)),
            (Double(half) / tibD,       .skyAccentDeep),
            (Double(wakeMin) / tibD,    Color(red: 0xD9/255, green: 0x7C/255, blue: 0x7C/255).opacity(0.6)),
            (Double(half) / tibD,       .skyAccentDeep),
        ]
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .leading) {
                LinearGradient(
                    colors: [Color(red: 0x0B/255, green: 0x11/255, blue: 0x1E/255).opacity(0.6),
                             Color(red: 0x16/255, green: 0x20/255, blue: 0x3A/255).opacity(0.6)],
                    startPoint: .top, endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))

                GeometryReader { geo in
                    HStack(spacing: 0) {
                        ForEach(Array(segments.enumerated()), id: \.offset) { i, seg in
                            Rectangle()
                                .fill(seg.color)
                                .frame(width: max(0, geo.size.width * seg.width), height: 28)
                                .clipShape(SegmentShape(isFirst: i == 0, isLast: i == segments.count - 1))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
            .frame(height: 44)

            HStack {
                Text(formatTime12h(inBed))
                Spacer()
                Text(formatTime12h(outBed))
            }
            .font(.system(size: 11))
            .foregroundStyle(Color.fg4)
        }
    }
}

private struct SegmentShape: Shape {
    var isFirst: Bool
    var isLast: Bool
    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 10
        let corners: UIRectCornerCompat = {
            if isFirst && isLast { return .all }
            if isFirst           { return .left }
            if isLast            { return .right }
            return .none
        }()
        return makeSegmentPath(rect: rect, radius: r, corners: corners)
    }
}

private enum UIRectCornerCompat {
    case all, left, right, none
}

fileprivate func makeSegmentPath(rect: CGRect, radius: CGFloat, corners: UIRectCornerCompat) -> Path {
    let tl: CGFloat = (corners == .all || corners == .left)  ? radius : 0
    let bl: CGFloat = (corners == .all || corners == .left)  ? radius : 0
    let tr: CGFloat = (corners == .all || corners == .right) ? radius : 0
    let br: CGFloat = (corners == .all || corners == .right) ? radius : 0

    var p = Path()
    p.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
    p.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
    if tr > 0 {
        p.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr,
                 startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
    }
    p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
    if br > 0 {
        p.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br,
                 startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
    }
    p.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
    if bl > 0 {
        p.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl,
                 startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
    }
    p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
    if tl > 0 {
        p.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl,
                 startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
    }
    p.closeSubpath()
    return p
}

// MARK: - Hypnogram (Apple Health style)

/// Stage-over-time chart. Stages stacked top→bottom: Awake, REM, Core, Deep.
/// Each event is drawn at its row's vertical position with a thin connector
/// rising/falling between rows so transitions read as continuous like Apple Health.
struct HypnogramView: View {
    var events: [HypnogramEvent]
    var windowStart: Date
    var windowEnd: Date

    private let rowOrder: [SleepStage] = [.awake, .rem, .light, .deep]
    private let rowHeight: CGFloat = 18
    private let rowGap: CGFloat = 4
    private let barThickness: CGFloat = 8

    private var totalSeconds: Double {
        max(1, windowEnd.timeIntervalSince(windowStart))
    }

    private func rowIndex(_ stage: SleepStage) -> Int {
        rowOrder.firstIndex(of: stage) ?? 0
    }

    private func xFor(_ date: Date, width: CGFloat) -> CGFloat {
        let dt = date.timeIntervalSince(windowStart)
        return width * CGFloat(max(0, min(1, dt / totalSeconds)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 0) {
                stageLabels
                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        gridBackground(width: geo.size.width)
                        chart(width: geo.size.width)
                    }
                }
            }
            .frame(height: CGFloat(rowOrder.count) * (rowHeight + rowGap))

            timeAxis
        }
    }

    private var stageLabels: some View {
        VStack(alignment: .trailing, spacing: rowGap) {
            ForEach(rowOrder, id: \.self) { stage in
                Text(stage.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(stage.color)
                    .frame(width: 44, height: rowHeight, alignment: .trailing)
            }
        }
        .padding(.trailing, 8)
    }

    private func gridBackground(width: CGFloat) -> some View {
        VStack(spacing: rowGap) {
            ForEach(rowOrder, id: \.self) { stage in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(stage.color.opacity(0.04))
                    .frame(height: rowHeight)
            }
        }
        .frame(width: width)
    }

    private func chart(width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            connectorPath(width: width)
                .stroke(Color.fg3.opacity(0.25), lineWidth: 1)

            ForEach(Array(events.enumerated()), id: \.offset) { _, ev in
                let x = xFor(ev.start, width: width)
                let w = max(1, xFor(ev.end, width: width) - x)
                let y = CGFloat(rowIndex(ev.stage)) * (rowHeight + rowGap) + (rowHeight - barThickness) / 2
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(ev.stage.color)
                    .frame(width: w, height: barThickness)
                    .offset(x: x, y: y)
            }
        }
    }

    private func connectorPath(width: CGFloat) -> Path {
        var p = Path()
        for (i, ev) in events.enumerated() {
            let xStart = xFor(ev.start, width: width)
            let xEnd = xFor(ev.end, width: width)
            let yMid = CGFloat(rowIndex(ev.stage)) * (rowHeight + rowGap) + rowHeight / 2
            if i == 0 {
                p.move(to: CGPoint(x: xStart, y: yMid))
            } else {
                p.addLine(to: CGPoint(x: xStart, y: yMid))
            }
            p.addLine(to: CGPoint(x: xEnd, y: yMid))
        }
        return p
    }

    private var timeAxis: some View {
        HStack {
            Text(formatClock(windowStart))
            Spacer()
            if let mid = midpointLabel { Text(mid) }
            Spacer()
            Text(formatClock(windowEnd))
        }
        .font(.system(size: 10))
        .foregroundStyle(Color.fg4)
        .padding(.leading, 52)
    }

    private var midpointLabel: String? {
        let mid = windowStart.addingTimeInterval(totalSeconds / 2)
        return formatClock(mid)
    }

    private func formatClock(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: d)
    }
}

// MARK: - Stage breakdown (Apple Health "Time in Stages" style)

struct StageBreakdownView: View {
    var remMin: Int
    var deepMin: Int
    var lightMin: Int
    var awakeMin: Int

    /// % is computed against total sleep time (REM + Light + Deep) for the asleep stages,
    /// matching Apple's "Time in Stages" rows. Awake gets its own row computed against TIB.
    private var tst: Int { remMin + lightMin + deepMin }
    private var tib: Int { tst + awakeMin }

    private func pctOfSleep(_ m: Int) -> Int {
        guard tst > 0 else { return 0 }
        return Int((Double(m) / Double(tst) * 100).rounded())
    }

    private func pctOfBed(_ m: Int) -> Int {
        guard tib > 0 else { return 0 }
        return Int((Double(m) / Double(tib) * 100).rounded())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            row(stage: .awake, minutes: awakeMin, percent: pctOfBed(awakeMin), maxMin: tib)
            row(stage: .rem,   minutes: remMin,   percent: pctOfSleep(remMin),   maxMin: tst)
            row(stage: .light, minutes: lightMin, percent: pctOfSleep(lightMin), maxMin: tst)
            row(stage: .deep,  minutes: deepMin,  percent: pctOfSleep(deepMin),  maxMin: tst)
        }
    }

    private func row(stage: SleepStage, minutes: Int, percent: Int, maxMin: Int) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(stage.color)
                    .frame(width: 4, height: 18)
                Text(stage.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.fg1)
            }
            .frame(width: 70, alignment: .leading)

            Text(formatStageDuration(minutes))
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Color.fg1)
                .frame(width: 70, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 8)
                    let frac = maxMin > 0 ? Double(minutes) / Double(maxMin) : 0
                    RoundedRectangle(cornerRadius: 4)
                        .fill(stage.color)
                        .frame(width: max(2, geo.size.width * CGFloat(frac)), height: 8)
                }
            }
            .frame(height: 8)

            Text("\(percent)%")
                .font(.system(size: 12))
                .monospacedDigit()
                .foregroundStyle(Color.fg3)
                .frame(width: 38, alignment: .trailing)
        }
    }
}

private func formatStageDuration(_ mins: Int) -> String {
    if mins == 0 { return "0m" }
    let h = mins / 60
    let m = mins % 60
    if h == 0 { return "\(m)m" }
    if m == 0 { return "\(h)h" }
    return "\(h)h \(m)m"
}

// MARK: - Stage mini bar

/// A single thin horizontal bar split into stage segments. Sized for use inline in
/// dashboard cards (Today's Last Night chip, Progress legends). Order matches
/// Apple Health's "Stages" pill: Awake → REM → Core → Deep.
struct StageMiniBar: View {
    var remMin: Int
    var deepMin: Int
    var lightMin: Int
    var awakeMin: Int
    var height: CGFloat = 6

    private var segments: [(SleepStage, Int)] {
        [(.awake, awakeMin), (.rem, remMin), (.light, lightMin), (.deep, deepMin)]
    }
    private var total: Int { segments.reduce(0) { $0 + $1.1 } }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 1) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                    let frac = total > 0 ? Double(seg.1) / Double(total) : 0
                    Rectangle()
                        .fill(seg.0.color)
                        .frame(width: max(0, geo.size.width * CGFloat(frac)))
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: height / 2))
        }
        .frame(height: height)
    }
}

// MARK: - Awakenings card

/// Compact "wake-ups" callout — number of disturbances + total awake time.
/// Sits next to the stage breakdown like Whoop's Disturbances tile.
struct AwakeningsCard: View {
    var count: Int
    var awakeMin: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "moon.zzz")
                    .font(.system(size: 11))
                    .foregroundStyle(SleepStage.awake.color)
                Text("AWAKENINGS").kicker()
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(count)")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.fg1)
                    .monospacedDigit()
                Text(count == 1 ? "time" : "times")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fg4)
            }
            Text("\(formatStageDuration(awakeMin)) awake")
                .font(.system(size: 11))
                .foregroundStyle(Color.fg3)
        }
    }
}

// MARK: - Sleep summary header (Apple-style hero)

/// Big "h:m" total + sub-line with restorative sleep and TIB. Used at the top of
/// the sleep detail block when stage data is available.
struct SleepSummaryHero: View {
    var tstMin: Int
    var tibMin: Int
    var restorativeMin: Int?
    var efficiency: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(tstMin / 60)")
                    .font(.system(size: 36, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color.fg1)
                Text("h")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.fg3)
                Text("\(tstMin % 60)")
                    .font(.system(size: 36, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color.fg1)
                Text("m")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.fg3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(efficiency)% efficiency")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.seSwiftUIColor(efficiency))
                if let r = restorativeMin {
                    Text("\(formatStageDuration(r)) restorative")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fg4)
                } else {
                    Text("\(formatStageDuration(tibMin)) in bed")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fg4)
                }
            }
        }
    }
}

// MARK: - Bar chart (sleep efficiency)

struct SEBarChart: View {
    var values: [(label: String, value: Int)]
    var target: Double = 85

    var body: some View {
        GeometryReader { geo in
            let pad: CGFloat = 8
            let chartW = geo.size.width - pad * 2
            let chartH = geo.size.height - pad * 2
            let step = chartW / CGFloat(Swift.max(1, values.count))
            let barW = step * 0.6

            ZStack {
                // grid lines
                ForEach([25, 50, 75], id: \.self) { y in
                    let yPos: CGFloat = pad + chartH - chartH * CGFloat(y) / 100
                    Path { p in
                        p.move(to: CGPoint(x: pad, y: yPos))
                        p.addLine(to: CGPoint(x: pad + chartW, y: yPos))
                    }
                    .stroke(Color.white.opacity(0.04), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                }
                // target line at 85%
                let targetY = pad + chartH - chartH * CGFloat(target) / 100
                Path { p in
                    p.move(to: CGPoint(x: pad, y: targetY))
                    p.addLine(to: CGPoint(x: pad + chartW, y: targetY))
                }
                .stroke(Color.good400.opacity(0.55), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))

                // bars
                ForEach(Array(values.enumerated()), id: \.offset) { i, v in
                    let h = chartH * CGFloat(v.value) / 100
                    let x = pad + step * CGFloat(i) + step / 2 - barW / 2
                    let y = pad + chartH - h
                    let color = Color.seSwiftUIColor(v.value)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.85))
                        .frame(width: barW, height: Swift.max(2, h))
                        .position(x: x + barW / 2, y: y + h / 2)
                }
            }
        }
    }
}
