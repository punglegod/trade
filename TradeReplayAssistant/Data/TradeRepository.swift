import Foundation
import Observation

@MainActor
@Observable
final class TradeRepository {
    struct MergeResult: Sendable {
        var merged: [TradeSnapshot]
        var conflictCount: Int
    }

    private let localStore: LocalTradeStore
    private let remoteDataSource: any TradeDataSource
    private let reportService: ReportService

    private(set) var trades: [TradeSnapshot] = []
    private(set) var syncState: SyncState = .idle

    var selectedSymbol: String = "全部"
    var selectedTag: String = "全部"

    private var didBootstrap = false
    private var lastSyncedCursor: Date?

    init(
        localStore: LocalTradeStore,
        remoteDataSource: any TradeDataSource,
        reportService: ReportService = ReportService()
    ) {
        self.localStore = localStore
        self.remoteDataSource = remoteDataSource
        self.reportService = reportService
    }

    var availableSymbols: [String] {
        let symbols = Set(
            trades
                .filter { !$0.isDeleted }
                .map(\.symbol)
                .filter { !$0.isEmpty }
        )
        return ["全部"] + symbols.sorted()
    }

    var availableTags: [String] {
        let tags = Set(
            trades
                .filter { !$0.isDeleted }
                .map(\.strategyTag)
                .filter { !$0.isEmpty }
        )
        return ["全部"] + tags.sorted()
    }

    var filteredTrades: [TradeSnapshot] {
        trades
            .filter { !$0.isDeleted }
            .filter { trade in
                selectedSymbol == "全部" || trade.symbol == selectedSymbol
            }
            .filter { trade in
                selectedTag == "全部" || trade.strategyTag == selectedTag
            }
            .sorted { $0.openTime > $1.openTime }
    }

    func bootstrap() async {
        guard !didBootstrap else {
            return
        }

        do {
            trades = try localStore.fetchAll()

            if trades.isEmpty {
                let seed = TradeSnapshot.demoSeed()
                try localStore.upsert(seed)
                trades = seed.sorted { $0.openTime > $1.openTime }
            }

            didBootstrap = true
            await sync()
        } catch {
            syncState = .failed(error.localizedDescription)
        }
    }

    func saveTrade(draft: TradeDraft, editingID: UUID?) async throws {
        let now = Date.now
        let existing = trades.first { $0.id == editingID }

        let snapshot = draft.toSnapshot(
            id: editingID ?? UUID(),
            createdAt: existing?.createdAt ?? now,
            updatedAt: now
        )

        try localStore.upsert(snapshot)
        applyLocalUpsert(snapshot)

        await sync()
    }

    func deleteTrade(id: UUID) async throws {
        let deletedAt = Date.now
        try localStore.softDelete(id: id, deletedAt: deletedAt)

        if let index = trades.firstIndex(where: { $0.id == id }) {
            trades[index].deletedAt = deletedAt
            trades[index].updatedAt = deletedAt
        }

        await sync()
    }

    func sync() async {
        syncState = .syncing

        do {
            let remote = try await remoteDataSource.fetchTrades(updatedAfter: lastSyncedCursor)
            let mergeResult = Self.mergeByLastWriteWins(local: trades, remote: remote)

            try localStore.upsert(mergeResult.merged)
            try await remoteDataSource.upsertTrades(mergeResult.merged)

            trades = mergeResult.merged
                .filter { !$0.isDeleted }
                .sorted { $0.openTime > $1.openTime }

            lastSyncedCursor = Date.now
            syncState = mergeResult.conflictCount > 0 ? .conflict(mergeResult.conflictCount) : .synced(Date.now)
        } catch {
            syncState = .failed(error.localizedDescription)
        }
    }

    func summary(for window: StatsRangeWindow) -> TradeSummary {
        reportService.generateSummary(
            trades: trades,
            within: window.interval()
        )
    }

    func weeklyReport(referenceDate: Date = .now) -> WeeklyReport {
        reportService.generateWeeklyReport(
            trades: trades,
            referenceDate: referenceDate
        )
    }

    nonisolated static func mergeByLastWriteWins(
        local: [TradeSnapshot],
        remote: [TradeSnapshot]
    ) -> MergeResult {
        var mergedDict = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        var conflictCount = 0

        for remoteItem in remote {
            if let localItem = mergedDict[remoteItem.id] {
                if remoteItem.updatedAt > localItem.updatedAt {
                    conflictCount += 1
                    mergedDict[remoteItem.id] = remoteItem
                } else if remoteItem.updatedAt < localItem.updatedAt {
                    conflictCount += 1
                } else if remoteItem != localItem {
                    conflictCount += 1
                }
            } else {
                mergedDict[remoteItem.id] = remoteItem
            }
        }

        return MergeResult(
            merged: mergedDict.values.sorted { $0.openTime > $1.openTime },
            conflictCount: conflictCount
        )
    }

    private func applyLocalUpsert(_ snapshot: TradeSnapshot) {
        if let index = trades.firstIndex(where: { $0.id == snapshot.id }) {
            trades[index] = snapshot
        } else {
            trades.append(snapshot)
        }

        trades.sort { $0.openTime > $1.openTime }
    }
}
