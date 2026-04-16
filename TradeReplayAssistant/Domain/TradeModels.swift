import Foundation

enum TradeDirection: String, Codable, CaseIterable, Identifiable, Sendable {
    case long = "做多"
    case short = "做空"

    var id: String { rawValue }
}

enum SyncState: Equatable, Sendable {
    case idle
    case syncing
    case synced(Date)
    case failed(String)
    case conflict(Int)
}

enum StatsRangeWindow: String, CaseIterable, Identifiable, Sendable {
    case last7Days = "近7天"
    case last30Days = "近30天"
    case yearToDate = "年内"

    var id: String { rawValue }

    func interval(referenceDate: Date = .now, calendar: Calendar = .current) -> DateInterval {
        switch self {
        case .last7Days:
            let start = calendar.date(byAdding: .day, value: -6, to: referenceDate) ?? referenceDate
            return DateInterval(start: calendar.startOfDay(for: start), end: referenceDate)
        case .last30Days:
            let start = calendar.date(byAdding: .day, value: -29, to: referenceDate) ?? referenceDate
            return DateInterval(start: calendar.startOfDay(for: start), end: referenceDate)
        case .yearToDate:
            let components = calendar.dateComponents([.year], from: referenceDate)
            let start = calendar.date(from: components) ?? referenceDate
            return DateInterval(start: start, end: referenceDate)
        }
    }
}

struct TradeSnapshot: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var symbol: String
    var direction: TradeDirection
    var openTime: Date
    var closeTime: Date
    var openPrice: Double
    var closePrice: Double
    var positionSize: Double
    var fee: Double
    var pnl: Double
    var strategyTag: String
    var mistakeTag: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var isWin: Bool { pnl > 0 }

    var holdingMinutes: Int {
        max(Int(closeTime.timeIntervalSince(openTime) / 60), 0)
    }

    var isDeleted: Bool {
        guard let deletedAt else { return false }
        return deletedAt <= .now
    }
}

struct TradeDraft: Sendable {
    var symbol: String = ""
    var direction: TradeDirection = .long
    var openTime: Date = .now
    var closeTime: Date = .now
    var openPrice: Double = 0
    var closePrice: Double = 0
    var positionSize: Double = 1
    var fee: Double = 0
    var strategyTag: String = "趋势"
    var mistakeTag: String = ""
    var notes: String = ""

    func toSnapshot(id: UUID, createdAt: Date, updatedAt: Date) -> TradeSnapshot {
        let directionMultiplier: Double = direction == .long ? 1 : -1
        let gross = (closePrice - openPrice) * positionSize * directionMultiplier
        let pnl = gross - fee

        return TradeSnapshot(
            id: id,
            symbol: symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            direction: direction,
            openTime: openTime,
            closeTime: closeTime,
            openPrice: openPrice,
            closePrice: closePrice,
            positionSize: positionSize,
            fee: fee,
            pnl: pnl,
            strategyTag: strategyTag.trimmingCharacters(in: .whitespacesAndNewlines),
            mistakeTag: mistakeTag.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: nil
        )
    }
}

struct TradeSummary: Sendable {
    var totalTrades: Int
    var winRate: Double
    var totalPnL: Double
    var averageWin: Double
    var averageLoss: Double
    var profitFactor: Double
    var maxDrawdown: Double

    static let empty = TradeSummary(
        totalTrades: 0,
        winRate: 0,
        totalPnL: 0,
        averageWin: 0,
        averageLoss: 0,
        profitFactor: 0,
        maxDrawdown: 0
    )
}

struct WeeklyReport: Sendable {
    var weekInterval: DateInterval
    var summary: TradeSummary
    var goodPractices: [String]
    var improvementAreas: [String]
    var nextWeekActions: [String]

    static func empty(for interval: DateInterval) -> WeeklyReport {
        WeeklyReport(
            weekInterval: interval,
            summary: .empty,
            goodPractices: ["本周暂无交易数据"],
            improvementAreas: ["先完成至少 5 笔可复盘交易"],
            nextWeekActions: ["交易结束后 10 分钟内填写复盘记录"]
        )
    }
}

extension TradeSnapshot {
    static func demoSeed(referenceDate: Date = .now) -> [TradeSnapshot] {
        let calendar = Calendar.current

        func makeDayOffset(_ day: Int, hour: Int, minute: Int) -> Date {
            let dayDate = calendar.date(byAdding: .day, value: day, to: referenceDate) ?? referenceDate
            return calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: dayDate
            ) ?? dayDate
        }

        return [
            TradeSnapshot(
                id: UUID(),
                symbol: "AAPL",
                direction: .long,
                openTime: makeDayOffset(-5, hour: 10, minute: 2),
                closeTime: makeDayOffset(-5, hour: 11, minute: 21),
                openPrice: 188.2,
                closePrice: 190.1,
                positionSize: 100,
                fee: 8,
                pnl: 182,
                strategyTag: "突破",
                mistakeTag: "",
                notes: "量价齐升后跟随，止盈执行良好。",
                createdAt: makeDayOffset(-5, hour: 11, minute: 22),
                updatedAt: makeDayOffset(-5, hour: 11, minute: 25),
                deletedAt: nil
            ),
            TradeSnapshot(
                id: UUID(),
                symbol: "TSLA",
                direction: .short,
                openTime: makeDayOffset(-3, hour: 9, minute: 44),
                closeTime: makeDayOffset(-3, hour: 10, minute: 15),
                openPrice: 171.5,
                closePrice: 173.0,
                positionSize: 80,
                fee: 7,
                pnl: -127,
                strategyTag: "回落",
                mistakeTag: "止损迟疑",
                notes: "触发止损后仍犹豫，扩大亏损。",
                createdAt: makeDayOffset(-3, hour: 10, minute: 16),
                updatedAt: makeDayOffset(-3, hour: 10, minute: 20),
                deletedAt: nil
            ),
            TradeSnapshot(
                id: UUID(),
                symbol: "NVDA",
                direction: .long,
                openTime: makeDayOffset(-1, hour: 13, minute: 2),
                closeTime: makeDayOffset(-1, hour: 14, minute: 10),
                openPrice: 943.0,
                closePrice: 951.8,
                positionSize: 20,
                fee: 6,
                pnl: 170,
                strategyTag: "趋势",
                mistakeTag: "",
                notes: "顺势加仓后分批止盈，执行稳定。",
                createdAt: makeDayOffset(-1, hour: 14, minute: 11),
                updatedAt: makeDayOffset(-1, hour: 14, minute: 14),
                deletedAt: nil
            )
        ]
    }
}
