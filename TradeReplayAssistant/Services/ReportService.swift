import Foundation

struct ReportService {
    func generateSummary(
        trades: [TradeSnapshot],
        within interval: DateInterval
    ) -> TradeSummary {
        let filtered = trades
            .filter { !$0.isDeleted }
            .filter { interval.contains($0.closeTime) }
            .sorted { $0.closeTime < $1.closeTime }

        guard !filtered.isEmpty else {
            return .empty
        }

        let wins = filtered.filter { $0.pnl > 0 }
        let losses = filtered.filter { $0.pnl < 0 }

        let totalPnL = filtered.reduce(0) { $0 + $1.pnl }
        let averageWin = wins.isEmpty ? 0 : wins.reduce(0) { $0 + $1.pnl } / Double(wins.count)
        let averageLoss = losses.isEmpty ? 0 : losses.reduce(0) { $0 + abs($1.pnl) } / Double(losses.count)
        let totalProfit = wins.reduce(0) { $0 + $1.pnl }
        let totalLoss = losses.reduce(0) { $0 + abs($1.pnl) }

        let runningEquity = filtered.reduce(into: [Double]()) { partial, trade in
            let next = (partial.last ?? 0) + trade.pnl
            partial.append(next)
        }

        var peak: Double = runningEquity.first ?? 0
        var maxDrawdown: Double = 0

        for equity in runningEquity {
            peak = max(peak, equity)
            maxDrawdown = max(maxDrawdown, peak - equity)
        }

        return TradeSummary(
            totalTrades: filtered.count,
            winRate: Double(wins.count) / Double(filtered.count),
            totalPnL: totalPnL,
            averageWin: averageWin,
            averageLoss: averageLoss,
            profitFactor: totalLoss == 0 ? totalProfit : totalProfit / totalLoss,
            maxDrawdown: maxDrawdown
        )
    }

    func generateWeeklyReport(
        trades: [TradeSnapshot],
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> WeeklyReport {
        let weekInterval = weekInterval(for: referenceDate, calendar: calendar)
        let summary = generateSummary(trades: trades, within: weekInterval)

        guard summary.totalTrades > 0 else {
            return .empty(for: weekInterval)
        }

        let weekTrades = trades
            .filter { !$0.isDeleted }
            .filter { weekInterval.contains($0.closeTime) }

        let goodPractices = topLabels(
            from: weekTrades.filter { $0.pnl > 0 }.map(\.strategyTag),
            fallback: ["执行了既定止盈规则", "保持了仓位控制", "记录了复盘笔记"]
        )

        let improvementSources = weekTrades
            .filter { $0.pnl < 0 }
            .map { $0.mistakeTag.isEmpty ? "出场纪律" : $0.mistakeTag }

        let improvementAreas = topLabels(
            from: improvementSources,
            fallback: ["减少冲动开仓", "严格执行止损", "收敛交易频率"]
        )

        let nextWeekActions = improvementAreas.map { "针对\($0)设定明确触发条件并盘后打分" }

        return WeeklyReport(
            weekInterval: weekInterval,
            summary: summary,
            goodPractices: goodPractices,
            improvementAreas: improvementAreas,
            nextWeekActions: nextWeekActions
        )
    }

    private func weekInterval(for date: Date, calendar: Calendar) -> DateInterval {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let start = calendar.date(from: components) ?? date
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? date
        return DateInterval(start: start, end: end)
    }

    private func topLabels(from values: [String], fallback: [String]) -> [String] {
        let cleaned = values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if cleaned.isEmpty {
            return fallback
        }

        let counter = cleaned.reduce(into: [String: Int]()) { partial, value in
            partial[value, default: 0] += 1
        }

        return counter
            .sorted {
                if $0.value == $1.value {
                    return $0.key < $1.key
                }
                return $0.value > $1.value
            }
            .prefix(3)
            .map(\.key)
    }
}
