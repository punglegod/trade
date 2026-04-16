import SwiftUI

struct TradeEditorSession: Identifiable {
    let id = UUID()
    var existingTrade: TradeSnapshot?
}

struct TradeEditorView: View {
    private let existingTrade: TradeSnapshot?
    private let onSave: (TradeDraft) async -> Void

    @State private var draft: TradeDraft
    @Environment(\.dismiss) private var dismiss

    init(
        existingTrade: TradeSnapshot? = nil,
        onSave: @escaping (TradeDraft) async -> Void
    ) {
        self.existingTrade = existingTrade
        self.onSave = onSave
        _draft = State(initialValue: Self.makeDraft(from: existingTrade))
    }

    var body: some View {
        Form {
            Section("基础信息") {
                TextField("标的（例如 AAPL）", text: $draft.symbol)
                    .textInputAutocapitalization(.characters)
                Picker("方向", selection: $draft.direction) {
                    ForEach(TradeDirection.allCases) { direction in
                        Text(direction.rawValue).tag(direction)
                    }
                }
                TextField("策略标签", text: $draft.strategyTag)
                TextField("错误标签（可选）", text: $draft.mistakeTag)
            }

            Section("价格与仓位") {
                TextField("开仓价", value: $draft.openPrice, format: .number)
                    .keyboardType(.decimalPad)
                TextField("平仓价", value: $draft.closePrice, format: .number)
                    .keyboardType(.decimalPad)
                TextField("仓位", value: $draft.positionSize, format: .number)
                    .keyboardType(.decimalPad)
                TextField("手续费", value: $draft.fee, format: .number)
                    .keyboardType(.decimalPad)
            }

            Section("时间") {
                DatePicker("开仓", selection: $draft.openTime)
                DatePicker("平仓", selection: $draft.closeTime)
            }

            Section("复盘备注") {
                TextField("记录关键判断、执行质量和改进点", text: $draft.notes, axis: .vertical)
                    .lineLimit(4...8)
            }
        }
        .navigationTitle(existingTrade == nil ? "新增交易" : "编辑交易")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    Task {
                        await onSave(draft)
                        dismiss()
                    }
                }
                .disabled(!canSave)
            }
        }
    }

    private var canSave: Bool {
        !draft.symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && draft.openPrice > 0
            && draft.closePrice > 0
            && draft.positionSize > 0
            && draft.closeTime >= draft.openTime
    }

    private static func makeDraft(from trade: TradeSnapshot?) -> TradeDraft {
        guard let trade else {
            return TradeDraft()
        }

        return TradeDraft(
            symbol: trade.symbol,
            direction: trade.direction,
            openTime: trade.openTime,
            closeTime: trade.closeTime,
            openPrice: trade.openPrice,
            closePrice: trade.closePrice,
            positionSize: trade.positionSize,
            fee: trade.fee,
            strategyTag: trade.strategyTag,
            mistakeTag: trade.mistakeTag,
            notes: trade.notes
        )
    }
}
