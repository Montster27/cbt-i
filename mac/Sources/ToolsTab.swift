import SwiftUI

struct ToolsTab: View {
    @State private var openedTool: String? = nil

    private var tools: [(id: String, title: String, when: String, desc: String, systemImage: String, color: Color, time: String)] {
        [
            ("breathing", "4-7-8 Breathing", "Pre-bed · night wakings",
             "Activate the vagal brake before sleep.", "wind", .skyAccent, "2 min"),
            ("bodyscan", "Body scan", "Night wakings · mind racing",
             "Shift attention from thought to sensation.", "sparkles", .warmAmber, "5 min"),
            ("worrypost", "Worry postponement", "11:30 PM routine",
             "Park tomorrow's problems before bed.", "square.and.pencil", .good400, "10 min"),
            ("defusion", "Leaves on a stream", "Anytime, in or out of bed",
             "Watch thoughts float by without grabbing.", "leaf.fill", .warmAmber, "5 min"),
            ("beliefs", "Sleep beliefs", "Morning reflection",
             "Examine what your mind insists is true.", "brain.head.profile", .warmAmber, "Self-paced"),
        ]
    }

    var body: some View {
        ScrollView {
            if let toolId = openedTool {
                ToolDetailView(toolId: toolId, onBack: { openedTool = nil })
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 36)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    ForEach(tools, id: \.id) { tool in
                        toolRow(tool)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 36)
            }
        }
        .scrollContentBackground(.hidden)
        .appBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TOOLKIT").kicker()
            Text("What do you need right now?")
                .font(.serifH1)
                .foregroundStyle(Color.fg1)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toolRow(_ tool: (id: String, title: String, when: String, desc: String, systemImage: String, color: Color, time: String)) -> some View {
        Button {
            openedTool = tool.id
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(tool.color.opacity(0.18))
                    Image(systemName: tool.systemImage)
                        .font(.system(size: 22))
                        .foregroundStyle(tool.color)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(tool.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.fg1)
                        Text("· \(tool.time)")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.fg4)
                    }
                    Text(tool.when)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fg4)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.fg4)
            }
            .padding(16)
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

struct ToolDetailView: View {
    let toolId: String
    let onBack: () -> Void

    private var stepTool: StepTool? { STEP_TOOLS.first { $0.id == toolId } }

    private var meta: (systemImage: String, color: Color, time: String) {
        switch toolId {
        case "breathing": return ("wind", .skyAccent, "2 min")
        case "bodyscan":  return ("sparkles", .warmAmber, "5 min")
        case "worrypost": return ("square.and.pencil", .good400, "10 min")
        case "defusion":  return ("leaf.fill", .warmAmber, "5 min")
        case "beliefs":   return ("brain.head.profile", .warmAmber, "Self-paced")
        default:          return ("wand.and.stars", .warmAmber, "")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").font(.system(size: 12, weight: .semibold))
                    Text("Toolkit")
                }
                .font(.system(size: 13))
                .foregroundStyle(Color.fg3)
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(meta.color.opacity(0.18))
                    Image(systemName: meta.systemImage)
                        .font(.system(size: 20))
                        .foregroundStyle(meta.color)
                }
                .frame(width: 40, height: 40)
                Text(meta.time.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Color.fg4)
            }

            if toolId == "beliefs" {
                beliefsBody
            } else if let t = stepTool {
                stepBody(t)
            }
        }
    }

    @ViewBuilder
    private func stepBody(_ t: StepTool) -> some View {
        Text(t.title)
            .font(.serifH1)
            .foregroundStyle(Color.fg1)
        WarmChip(text: t.when, tint: .accent)
        Text(t.desc)
            .font(.system(size: 14))
            .foregroundStyle(Color.fg2)
            .padding(.bottom, 8)

        Text("HOW TO PRACTICE").kicker()
        ForEach(Array(t.steps.enumerated()), id: \.offset) { i, step in
            HStack(alignment: .top, spacing: 12) {
                Text("\(i + 1)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.warmAmberStrong)
                    .frame(width: 26, height: 26)
                    .background(Color.warmAmberSoft)
                    .clipShape(Circle())
                Text(step)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.fg2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .warmCard(padding: 14)
        }
    }

    @ViewBuilder
    private var beliefsBody: some View {
        Text(BELIEFS_TOOL.title)
            .font(.serifH1)
            .foregroundStyle(Color.fg1)
        WarmChip(text: BELIEFS_TOOL.when, tint: .accent)
        Text(BELIEFS_TOOL.desc)
            .font(.system(size: 14))
            .foregroundStyle(Color.fg2)
            .padding(.bottom, 8)

        Text("FIVE BELIEFS TO EXAMINE").kicker()
        ForEach(BELIEFS_TOOL.items) { item in
            VStack(alignment: .leading, spacing: 10) {
                Text("\u{201C}\(item.belief)\u{201D}")
                    .font(.system(size: 15, design: .serif))
                    .italic()
                    .foregroundStyle(Color.fg1)
                Text("REFRAME")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(Color.warmAmber)
                Text(item.reframe)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.fg2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .warmCard()
        }
    }
}
