import Foundation
import SwiftData

@MainActor
final class LocalTradeStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [TradeSnapshot] {
        var descriptor = FetchDescriptor<TradeRecord>(
            sortBy: [SortDescriptor(\TradeRecord.openTime, order: .reverse)]
        )
        descriptor.fetchLimit = 5_000
        return try context.fetch(descriptor).map(\.snapshot)
    }

    func upsert(_ snapshots: [TradeSnapshot]) throws {
        for snapshot in snapshots {
            try upsert(snapshot)
        }
        if context.hasChanges {
            try context.save()
        }
    }

    func upsert(_ snapshot: TradeSnapshot) throws {
        let targetID = snapshot.id
        let descriptor = FetchDescriptor<TradeRecord>(predicate: #Predicate { $0.id == targetID })

        if let existing = try context.fetch(descriptor).first {
            guard existing.updatedAt <= snapshot.updatedAt else {
                return
            }
            existing.update(from: snapshot)
        } else {
            context.insert(TradeRecord(snapshot: snapshot))
        }
    }

    func softDelete(id: UUID, deletedAt: Date = .now) throws {
        let targetID = id
        let descriptor = FetchDescriptor<TradeRecord>(predicate: #Predicate { $0.id == targetID })
        guard let existing = try context.fetch(descriptor).first else {
            return
        }

        existing.deletedAt = deletedAt
        existing.updatedAt = deletedAt

        if context.hasChanges {
            try context.save()
        }
    }
}
