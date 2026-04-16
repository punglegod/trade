import Foundation
import SwiftData

@Model
final class TradeRecord {
    @Attribute(.unique) var id: UUID
    var symbol: String
    var directionRaw: String
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

    init(snapshot: TradeSnapshot) {
        self.id = snapshot.id
        self.symbol = snapshot.symbol
        self.directionRaw = snapshot.direction.rawValue
        self.openTime = snapshot.openTime
        self.closeTime = snapshot.closeTime
        self.openPrice = snapshot.openPrice
        self.closePrice = snapshot.closePrice
        self.positionSize = snapshot.positionSize
        self.fee = snapshot.fee
        self.pnl = snapshot.pnl
        self.strategyTag = snapshot.strategyTag
        self.mistakeTag = snapshot.mistakeTag
        self.notes = snapshot.notes
        self.createdAt = snapshot.createdAt
        self.updatedAt = snapshot.updatedAt
        self.deletedAt = snapshot.deletedAt
    }

    func update(from snapshot: TradeSnapshot) {
        symbol = snapshot.symbol
        directionRaw = snapshot.direction.rawValue
        openTime = snapshot.openTime
        closeTime = snapshot.closeTime
        openPrice = snapshot.openPrice
        closePrice = snapshot.closePrice
        positionSize = snapshot.positionSize
        fee = snapshot.fee
        pnl = snapshot.pnl
        strategyTag = snapshot.strategyTag
        mistakeTag = snapshot.mistakeTag
        notes = snapshot.notes
        createdAt = snapshot.createdAt
        updatedAt = snapshot.updatedAt
        deletedAt = snapshot.deletedAt
    }

    var snapshot: TradeSnapshot {
        TradeSnapshot(
            id: id,
            symbol: symbol,
            direction: TradeDirection(rawValue: directionRaw) ?? .long,
            openTime: openTime,
            closeTime: closeTime,
            openPrice: openPrice,
            closePrice: closePrice,
            positionSize: positionSize,
            fee: fee,
            pnl: pnl,
            strategyTag: strategyTag,
            mistakeTag: mistakeTag,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}
