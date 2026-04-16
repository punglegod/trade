import Foundation

actor MockRemoteDataSource: TradeDataSource {
    private var storage: [UUID: TradeSnapshot]
    private let simulatedLatencyNanoseconds: UInt64
    private let simulatedFailureRate: Double

    init(
        seed: [TradeSnapshot] = TradeSnapshot.demoSeed(),
        simulatedLatencyNanoseconds: UInt64 = 350_000_000,
        simulatedFailureRate: Double = 0.08
    ) {
        self.storage = Dictionary(uniqueKeysWithValues: seed.map { ($0.id, $0) })
        self.simulatedLatencyNanoseconds = simulatedLatencyNanoseconds
        self.simulatedFailureRate = simulatedFailureRate
    }

    func fetchTrades(updatedAfter: Date?) async throws -> [TradeSnapshot] {
        try await Task.sleep(nanoseconds: simulatedLatencyNanoseconds)
        try simulateFailureIfNeeded()

        let values = storage.values.filter { snapshot in
            guard let updatedAfter else { return true }
            return snapshot.updatedAt > updatedAfter
        }

        return values.sorted { $0.updatedAt > $1.updatedAt }
    }

    func upsertTrades(_ trades: [TradeSnapshot]) async throws {
        try await Task.sleep(nanoseconds: simulatedLatencyNanoseconds)
        try simulateFailureIfNeeded()

        for trade in trades {
            if let existing = storage[trade.id], existing.updatedAt > trade.updatedAt {
                continue
            }
            storage[trade.id] = trade
        }
    }

    private func simulateFailureIfNeeded() throws {
        let roll = Double.random(in: 0...1)
        if roll < simulatedFailureRate {
            throw TradeDataSourceError.networkUnavailable
        }
    }
}
