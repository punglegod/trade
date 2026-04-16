import Foundation
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
