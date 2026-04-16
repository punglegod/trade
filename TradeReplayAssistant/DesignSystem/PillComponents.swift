import SwiftUI

struct PillButtonStyle: ButtonStyle {
    var prominent: Bool = false

    @Environment(\.appVisualStyle) private var style

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, style.chipHorizontalPadding)
            .frame(height: style.chipHeight)
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .background(
                Capsule(style: .continuous)
                    .fill(prominent ? style.accentColor : Color.white.opacity(0.55))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(prominent ? 0.15 : 0.55), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

extension Button {
    @ViewBuilder
    func appActionButtonStyle(prominent: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                self.buttonStyle(.glassProminent)
            } else {
                self.buttonStyle(.glass)
            }
        } else {
            self.buttonStyle(PillButtonStyle(prominent: prominent))
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.appVisualStyle) private var style

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? style.accentColor : Color.primary)
                .padding(.horizontal, style.chipHorizontalPadding)
                .frame(height: style.chipHeight)
        }
        .buttonStyle(.plain)
        .modifier(PillSurfaceModifier(isSelected: isSelected, interactive: true))
        .accessibilityLabel("筛选：\(title)")
    }
}

struct PillSegmentedControl<Option: Hashable & Identifiable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.id) { option in
                    FilterChip(
                        title: title(option),
                        isSelected: selection.id == option.id
                    ) {
                        selection = option
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}
