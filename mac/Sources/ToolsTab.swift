import SwiftUI

struct ToolsTab: View {
    @State private var selectedToolId: String = "breathing"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            picker
            ScrollView {
                if selectedToolId == "beliefs" {
                    beliefsView
                        .padding(20)
                } else if let tool = STEP_TOOLS.first(where: { $0.id == selectedToolId }) {
                    stepView(tool)
                        .padding(20)
                }
            }
        }
    }

    private var picker: some View {
        HStack(spacing: 6) {
            ForEach(STEP_TOOLS) { tool in
                pillButton(tool.id, label: shortLabel(tool.id))
            }
            pillButton("beliefs", label: "Sleep beliefs")
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private func shortLabel(_ id: String) -> String {
        switch id {
        case "breathing": return "Breathing"
        case "bodyscan": return "Body scan"
        case "worrypost": return "Worry postponement"
        case "defusion": return "Defusion"
        default: return id
        }
    }

    private func pillButton(_ id: String, label: String) -> some View {
        let active = selectedToolId == id
        return Button {
            selectedToolId = id
        } label: {
            Text(label)
                .font(.caption)
                .fontWeight(active ? .medium : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(active ? Color.secondary.opacity(0.18) : Color.clear)
                )
                .overlay(
                    Capsule().stroke(
                        active ? Color.primary.opacity(0.4) : Color.secondary.opacity(0.3),
                        lineWidth: 0.5
                    )
                )
                .foregroundStyle(active ? .primary : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func stepView(_ tool: StepTool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(tool.title)
                .font(.title3)
                .fontWeight(.medium)

            Text(tool.when)
                .font(.caption)
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(Capsule())

            Text(tool.desc)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(tool.steps.enumerated()), id: \.offset) { i, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(i + 1)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .frame(width: 22, height: 22)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Circle())
                        Text(step)
                            .font(.callout)
                            .foregroundStyle(.primary.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var beliefsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(BELIEFS_TOOL.desc)
                .font(.callout)
                .foregroundStyle(.secondary)

            ForEach(BELIEFS_TOOL.items) { item in
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\u{201C}\(item.belief)\u{201D}")
                            .font(.callout)
                            .fontWeight(.medium)
                        Text("REFRAME")
                            .font(.caption2)
                            .kerning(0.6)
                            .foregroundStyle(.tertiary)
                        Text(item.reframe)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(8)
                }
            }
        }
    }
}
