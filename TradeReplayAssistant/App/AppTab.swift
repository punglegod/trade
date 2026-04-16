import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case records
    case stats
    case report

    var id: String { rawValue }

    var title: String {
        switch self {
        case .records:
            return "记录"
        case .stats:
            return "统计"
        case .report:
            return "周报"
        }
    }

    var systemImage: String {
        switch self {
        case .records:
            return "list.bullet.rectangle"
        case .stats:
            return "chart.line.uptrend.xyaxis"
        case .report:
            return "doc.text.image"
        }
    }
}
