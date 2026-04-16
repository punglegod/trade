import SwiftUI

enum GlassProminence {
    case subtle
    case regular
    case strong
}

struct GlassGroup<Content: View>: View {
    private let spacing: CGFloat?
    private let content: Content

    init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    @Environment(\.appVisualStyle) private var style

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing ?? style.glassGroupSpacing) {
                content
            }
        } else {
            content
        }
    }
}

struct GlassCard<Content: View>: View {
    private let prominence: GlassProminence
    private let interactive: Bool
    private let content: Content

    init(
        prominence: GlassProminence = .regular,
        interactive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.prominence = prominence
        self.interactive = interactive
        self.content = content()
    }

    @Environment(\.appVisualStyle) private var style

    var body: some View {
        if #available(iOS 26.0, *) {
            content
                .padding(style.cardPadding)
                .glassEffect(glassStyle, in: .rect(cornerRadius: style.cardCornerRadius))
        } else {
            content
                .padding(style.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: style.cardCornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: style.cardCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                )
        }
    }

    @available(iOS 26.0, *)
    private var glassStyle: Glass {
        var base: Glass

        switch prominence {
        case .subtle:
            base = .regular.tint(.white.opacity(0.12))
        case .regular:
            base = .regular.tint(style.accentColor.opacity(0.12))
        case .strong:
            base = .regular.tint(style.accentColor.opacity(0.22))
        }

        return interactive ? base.interactive() : base
    }
}

struct PillSurfaceModifier: ViewModifier {
    var isSelected: Bool
    var interactive: Bool

    @Environment(\.appVisualStyle) private var style

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(glassStyle, in: .capsule)
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule().stroke(
                        isSelected ? style.accentColor.opacity(0.55) : Color.white.opacity(0.35),
                        lineWidth: 1
                    )
                )
        }
    }

    @available(iOS 26.0, *)
    private var glassStyle: Glass {
        let tint = isSelected ? style.accentColor.opacity(0.28) : Color.white.opacity(0.12)
        let base = Glass.regular.tint(tint)
        return interactive ? base.interactive() : base
    }
}
