import Foundation

enum TradeDataSourceError: LocalizedError {
    case networkUnavailable
    case malformedPayload

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "网络连接不可用，请稍后重试。"
        case .malformedPayload:
            return "远端数据格式异常。"
        }
    }
}

protocol TradeDataSource: Sendable {
    func fetchTrades(updatedAfter: Date?) async throws -> [TradeSnapshot]
    func upsertTrades(_ trades: [TradeSnapshot]) async throws
}
