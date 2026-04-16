import Foundation
import SwiftData
import XCTest
@testable import TradeReplayAssistant

final class TradeRepositoryTests: XCTestCase {
    func testMergeByLastWriteWinsUsesNewestSnapshot() {
        let id = UUID()
        let baseDate = Date.now

        let local = TradeSnapshot(
            id: id,
            symbol: "TSLA",
            direction: .long,
            openTime: baseDate,
            closeTime: baseDate,
            openPrice: 100,
            closePrice: 102,
            positionSize: 1,
            fee: 0,
            pnl: 2,
            strategyTag: "突破",
            mistakeTag: "",
            notes: "local",
            createdAt: baseDate,
            updatedAt: baseDate,
            deletedAt: nil
        )

        let remote = TradeSnapshot(
            id: id,
            symbol: "TSLA",
            direction: .long,
            openTime: baseDate,
            closeTime: baseDate,
            openPrice: 100,
            closePrice: 105,
            positionSize: 1,
            fee: 0,
            pnl: 5,
            strategyTag: "突破",
            mistakeTag: "",
            notes: "remote",
            createdAt: baseDate,
            updatedAt: baseDate.addingTimeInterval(60),
            deletedAt: nil
        )

        let result = TradeRepository.mergeByLastWriteWins(local: [local], remote: [remote])

        XCTAssertEqual(result.merged.count, 1)
        XCTAssertEqual(result.merged.first?.pnl, 5)
        XCTAssertEqual(result.conflictCount, 1)
    }

    func testMergeByLastWriteWinsKeepsBothWhenIDsDiffer() {
        let local = sampleTrade(symbol: "AAPL", pnl: 10)
        let remote = sampleTrade(symbol: "NVDA", pnl: -4)

        let result = TradeRepository.mergeByLastWriteWins(local: [local], remote: [remote])

        XCTAssertEqual(result.merged.count, 2)
        XCTAssertEqual(result.conflictCount, 0)
    }

    @MainActor
    func testRecordStatsReportFlowKeepsBusinessPathWorking() async throws {
        let container = try ModelContainer(
            for: TradeRecord.self,
            configurations: ModelConfiguration("TradeReplayAssistantFlowTests", isStoredInMemoryOnly: true)
        )

        let repository = TradeRepository(
            localStore: LocalTradeStore(context: ModelContext(container)),
            remoteDataSource: MockRemoteDataSource(
                seed: [],
                simulatedLatencyNanoseconds: 0,
                simulatedFailureRate: 0
            )
        )

        let now = Date.now
        let firstTrade = TradeDraft(
            symbol: "aapl",
            direction: .long,
            openTime: now.addingTimeInterval(-3_600),
            closeTime: now.addingTimeInterval(-1_800),
            openPrice: 100,
            closePrice: 110,
            positionSize: 1,
            fee: 0,
            strategyTag: "趋势",
            mistakeTag: "",
            notes: "first"
        )

        let secondTrade = TradeDraft(
            symbol: "tsla",
            direction: .short,
            openTime: now.addingTimeInterval(-7_200),
            closeTime: now.addingTimeInterval(-5_400),
            openPrice: 100,
            closePrice: 90,
            positionSize: 1,
            fee: 0,
            strategyTag: "回落",
            mistakeTag: "",
            notes: "second"
        )

        try await repository.saveTrade(draft: firstTrade, editingID: nil)
        try await repository.saveTrade(draft: secondTrade, editingID: nil)

        let summaryAfterCreate = repository.summary(for: .last7Days)
        XCTAssertEqual(summaryAfterCreate.totalTrades, 2)
        XCTAssertEqual(summaryAfterCreate.totalPnL, 20, accuracy: 0.0001)

        let reportAfterCreate = repository.weeklyReport(referenceDate: now)
        XCTAssertEqual(reportAfterCreate.summary.totalTrades, 2)

        guard let firstID = repository.filteredTrades.first(where: { $0.symbol == "AAPL" })?.id else {
            XCTFail("Expected inserted trade not found")
            return
        }

        try await repository.deleteTrade(id: firstID)

        let summaryAfterDelete = repository.summary(for: .last7Days)
        XCTAssertEqual(summaryAfterDelete.totalTrades, 1)
        XCTAssertEqual(summaryAfterDelete.totalPnL, 10, accuracy: 0.0001)

        let reportAfterDelete = repository.weeklyReport(referenceDate: now)
        XCTAssertEqual(reportAfterDelete.summary.totalTrades, 1)
    }

    private func sampleTrade(symbol: String, pnl: Double) -> TradeSnapshot {
        let now = Date.now
        return TradeSnapshot(
            id: UUID(),
            symbol: symbol,
            direction: .long,
            openTime: now,
            closeTime: now,
            openPrice: 10,
            closePrice: 11,
            positionSize: 1,
            fee: 0,
            pnl: pnl,
            strategyTag: "趋势",
            mistakeTag: "",
            notes: "",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil
        )
    }
}
