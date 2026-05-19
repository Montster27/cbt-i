import SwiftUI
import SwiftData

struct ProgramTab: View {
    @Query private var logs: [SleepLog]
    @State private var activeWeek: Int = 0

    var currentWeek: Int { weekNumber(from: logs) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                timeline
                weekDetail
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 36)
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .onAppear {
            if activeWeek == 0 { activeWeek = max(0, currentWeek - 1) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("6-WEEK PROGRAM").kicker()
            Text("Restructure sleep, gently.")
                .font(.serifH1)
                .foregroundStyle(Color.fg1)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timeline: some View {
        VStack(spacing: 2) {
            ForEach(Array(WEEKS.enumerated()), id: \.offset) { idx, w in
                timelineRow(week: w, index: idx)
            }
        }
        .padding(.bottom, 4)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.borderSoft)
                .frame(width: 2)
                .padding(.leading, 19)
                .padding(.vertical, 18)
        }
    }

    private func timelineRow(week: WeekContent, index: Int) -> some View {
        let state = stateOf(index: index)
        let isSelected = activeWeek == index
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { activeWeek = index }
        } label: {
            HStack(alignment: .center, spacing: 14) {
                node(for: state, label: "\(week.id)")
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(week.theme)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(state == .upcoming ? Color.fg2 : Color.fg1)
                        if state == .current {
                            WarmChip(text: "now", tint: .accent)
                        }
                    }
                    Text(week.title)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fg4)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .padding(.trailing, 10)
            .padding(.leading, 0)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.warmAmberSoft : .clear)
            )
        }
        .buttonStyle(.plain)
    }

    private enum WeekState { case done, current, upcoming }
    private func stateOf(index: Int) -> WeekState {
        if index + 1 < currentWeek { return .done }
        if index + 1 == currentWeek { return .current }
        return .upcoming
    }

    private func node(for state: WeekState, label: String) -> some View {
        Group {
            switch state {
            case .done:
                ZStack {
                    Circle().fill(Color.warmAmber)
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 0x06/255, green: 0x09/255, blue: 0x12/255))
                }
            case .current:
                ZStack {
                    Circle().fill(Color.bgApp)
                    Circle().strokeBorder(Color.warmAmber, lineWidth: 2)
                    Circle()
                        .strokeBorder(Color.warmAmber.opacity(0.18), lineWidth: 6)
                        .scaleEffect(1.3)
                        .blur(radius: 2)
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.warmAmberStrong)
                }
            case .upcoming:
                ZStack {
                    Circle()
                        .fill(Color.bgSurface)
                        .overlay(Circle().strokeBorder(Color.borderDefault, lineWidth: 1))
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.fg4)
                }
            }
        }
        .frame(width: 40, height: 40)
    }

    private var weekDetail: some View {
        let w = WEEKS[activeWeek]
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("WEEK \(w.id)")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Color.warmAmberStrong)
                Text(w.theme)
                    .font(.serifH2)
                    .foregroundStyle(Color.fg1)
                Text(w.title)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.fg3)
                HStack(spacing: 8) {
                    WarmChip(text: "Bed \(w.bedtime)", systemImage: "moon.fill")
                    WarmChip(text: "Wake 5:45 AM", systemImage: "sun.max.fill")
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            Divider().background(Color.borderSoft)

            VStack(alignment: .leading, spacing: 10) {
                Text("RULES THIS WEEK").kicker()
                ForEach(Array(w.rules.enumerated()), id: \.offset) { i, rule in
                    if i > 0 { Divider().background(Color.borderSoft) }
                    HStack(alignment: .top, spacing: 12) {
                        Circle().fill(Color.warmAmber).frame(width: 4, height: 4).padding(.top, 8)
                        Text(rule)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.fg2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            Divider().background(Color.borderSoft)

            VStack(alignment: .leading, spacing: 6) {
                Text("WHAT TO EXPECT")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Color.warmAmber)
                Text(w.expect)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.fg2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.warmAmber.opacity(0.05))

            if let cog = w.cognitive {
                Divider().background(Color.borderSoft)
                VStack(alignment: .leading, spacing: 6) {
                    Text("COGNITIVE FOCUS")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(Color.skyAccent)
                    Text(cog)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fg2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.skyAccent.opacity(0.06))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.bgElev)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.borderSoft, lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
