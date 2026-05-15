import SwiftUI
import SwiftData

struct ProgramTab: View {
    @Query private var logs: [SleepLog]
    @State private var activeWeek: Int = 0

    var currentWeek: Int { weekNumber(from: logs) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                weekPicker

                let w = WEEKS[activeWeek]

                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WEEK \(activeWeek + 1)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .kerning(1)

                        Text(w.title)
                            .font(.title3)
                            .fontWeight(.medium)

                        Text(w.theme)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            statTile("Bedtime", w.bedtime)
                            statTile("Wake time", "5:45 AM")
                        }
                        .padding(.top, 4)

                        Divider()

                        Text("Rules for this week")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(w.rules.enumerated()), id: \.offset) { i, rule in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(i + 1)")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .frame(width: 22, height: 22)
                                        .background(Color.accentColor.opacity(0.15))
                                        .foregroundStyle(Color.accentColor)
                                        .clipShape(Circle())
                                    Text(rule)
                                        .font(.callout)
                                        .foregroundStyle(.primary.opacity(0.85))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    .padding(8)
                }

                GroupBox(label: Label("What to expect", systemImage: "info.circle")) {
                    Text(w.expect)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let cognitive = w.cognitive {
                    HStack(alignment: .top, spacing: 12) {
                        Rectangle().fill(Color.accentColor).frame(width: 3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("COGNITIVE FOCUS")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.tertiary)
                                .kerning(0.6)
                            Text(cognitive)
                                .font(.callout)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
            }
            .padding(20)
        }
    }

    private var weekPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WEEKS) { w in
                    let i = w.id - 1
                    let isCurrent = w.id == currentWeek
                    let isActive = i == activeWeek
                    Button {
                        activeWeek = i
                    } label: {
                        HStack(spacing: 4) {
                            Text("Week \(w.id)")
                            if isCurrent { Text("←").font(.caption) }
                        }
                        .font(.caption)
                        .fontWeight(isActive ? .semibold : .regular)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(
                                isCurrent ? Color.accentColor.opacity(0.18) :
                                isActive ? Color.secondary.opacity(0.18) : Color.clear
                            )
                        )
                        .overlay(
                            Capsule().stroke(
                                isCurrent ? Color.accentColor.opacity(0.6) :
                                isActive ? Color.primary.opacity(0.4) : Color.secondary.opacity(0.3),
                                lineWidth: 0.5
                            )
                        )
                        .foregroundStyle(isCurrent ? Color.accentColor : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func statTile(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.tertiary)
            Text(value).font(.subheadline).fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
