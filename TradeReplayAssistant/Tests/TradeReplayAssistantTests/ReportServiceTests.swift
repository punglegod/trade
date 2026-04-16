import Foundation
import XCTest
@testable import TradeReplayAssistant

final class ReportServiceTests: XCTestCase {
    func testGenerateSummaryCalculatesCoreMetrics() {
        let service = ReportService()
        let now = Date.now
        let interval = DateInterval(
            start: Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now,
            end: now
        )

        let trades = [
            makeTrade(pnl: 100, dayOffset: -4),
            makeTrade(pnl: -50, dayOffset: -3),
            makeTrade(pnl: 30, dayOffset: -1)
        ]

        let summary = service.generateSummary(trades: trades, within: interval)

        XCTAssertEqual(summary.totalTrades, 3)
        XCTAssertEqual(summary.totalPnL, 80, accuracy: 0.0001)
        XCTAssertEqual(summary.winRate, 2.0 / 3.0, accuracy: 0.0001)
        XCTAssertEqual(summary.averageWin, 65, accuracy: 0.0001)
        XCTAssertEqual(summary.averageLoss, 50, accuracy: 0.0001)
    }

    func testGenerateWeeklyReportReturnsFallbackWhenNoTrades() {
        let service = ReportService()
        let report = service.generateWeeklyReport(trades: [], referenceDate: .now)

        XCTAssertEqual(report.summary.totalTrades, 0)
        XCTAssertFalse(report.goodPractices.isEmpty)
        XCTAssertFalse(report.improvementAreas.isEmpty)
        XCTAssertFalse(report.nextWeekActions.isEmpty)
    }

    private func makeTrade(pnl: Double, dayOffset: Int) -> TradeSnapshot {
        let calendar = Calendar.current
        let now = Date.now
        let openTime = calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
        let closeTime = calendar.date(byAdding: .hour, value: 1, to: openTime) ?? openTime

        return TradeSnapshot(
            id: UUID(),
            symbol: "AAPL",
            direction: .long,
            openTime: openTime,
            closeTime: closeTime,
            openPrice: 100,
            closePrice: 101,
            positionSize: 1,
            fee: 0,
            pnl: pnl,
            strategyTag: "趋势",
            mistakeTag: "",
            notes: "",
            createdAt: openTime,
            updatedAt: closeTime,
            deletedAt: nil
        )
    }
}
