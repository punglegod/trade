import SwiftUI

protocol AppVisualStyle {
    var sectionSpacing: CGFloat { get }
    var cardCornerRadius: CGFloat { get }
    var chipHeight: CGFloat { get }
    var cardPadding: CGFloat { get }
    var accentColor: Color { get }
    var chipHorizontalPadding: CGFloat { get }
    var glassGroupSpacing: CGFloat { get }
    var screenHorizontalPadding: CGFloat { get }
    var screenBackground: LinearGradient { get }
    func supportsNativeGlass() -> Bool
}

struct DefaultAppVisualStyle: AppVisualStyle {
    var sectionSpacing: CGFloat = 16
    var cardCornerRadius: CGFloat = 24
    var chipHeight: CGFloat = 34
    var cardPadding: CGFloat = 16
    var accentColor: Color = Color(red: 0.07, green: 0.41, blue: 0.95)
    var chipHorizontalPadding: CGFloat = 14
    var glassGroupSpacing: CGFloat = 18
    var screenHorizontalPadding: CGFloat = 16

    var screenBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.97, green: 0.98, blue: 1.0),
                Color(red: 0.94, green: 0.97, blue: 1.0),
                Color(red: 0.98, green: 0.99, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func supportsNativeGlass() -> Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }
}

private struct AppVisualStyleKey: EnvironmentKey {
    static let defaultValue = DefaultAppVisualStyle()
}

extension EnvironmentValues {
    var appVisualStyle: DefaultAppVisualStyle {
        get { self[AppVisualStyleKey.self] }
        set { self[AppVisualStyleKey.self] = newValue }
    }
}
