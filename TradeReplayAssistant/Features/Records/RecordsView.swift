import SwiftUI

struct RecordsView: View {
    @Environment(TradeRepository.self) private var repository
    @Environment(\.appVisualStyle) private var style

    @State private var editorSession: TradeEditorSession?
    @State private var activeErrorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: style.sectionSpacing) {
                filterSection
                syncStateBanner
                tradeListSection
            }
            .padding(.horizontal, style.screenHorizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(style.screenBackground.ignoresSafeArea())
        .navigationTitle("交易记录")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editorSession = TradeEditorSession(existingTrade: nil)
                } label: {
                    Label("新增", systemImage: "plus")
                }
                .appActionButtonStyle(prominent: true)
            }
        }
        .sheet(item: $editorSession) { session in
            NavigationStack {
                TradeEditorView(existingTrade: session.existingTrade) { draft in
                    do {
                        try await repository.saveTrade(
                            draft: draft,
                            editingID: session.existingTrade?.id
                        )
                    } catch {
                        activeErrorMessage = error.localizedDescription
                    }
                }
            }
        }
        .alert("操作失败", isPresented: Binding(
            get: { activeErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    activeErrorMessage = nil
                }
            }
        )) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(activeErrorMessage ?? "未知错误")
        }
        .refreshable {
            await repository.sync()
        }
    }

    private var filterSection: some View {
        GlassGroup {
            VStack(alignment: .leading, spacing: 10) {
                Text("标的")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(repository.availableSymbols, id: \.self) { symbol in
                            FilterChip(
                                title: symbol,
                                isSelected: repository.selectedSymbol == symbol
                            ) {
                                repository.selectedSymbol = symbol
                            }
                        }
                    }
                }

                Text("策略")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(repository.availableTags, id: \.self) { tag in
                            FilterChip(
                                title: tag,
                                isSelected: repository.selectedTag == tag
                            ) {
                                repository.selectedTag = tag
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private var syncStateBanner: some View {
        switch repository.syncState {
        case .idle:
            EmptyView()
        case .syncing:
            GlassCard(prominence: .subtle) {
                Label("正在同步远端数据…", systemImage: "arrow.triangle.2.circlepath")
                    .font(.footnote)
            }
        case .synced(let date):
            GlassCard(prominence: .subtle) {
                Label("已同步：\(date.formatted(date: .omitted, time: .shortened))", systemImage: "checkmark.seal")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        case .failed(let reason):
            GlassCard(prominence: .strong) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("同步失败", systemImage: "exclamationmark.triangle")
                        .font(.footnote.weight(.semibold))
                    Text(reason)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        case .conflict(let count):
            GlassCard(prominence: .regular) {
                Label("检测到 \(count) 条冲突，已按最新更新时间合并", systemImage: "arrow.triangle.branch")
                    .font(.footnote)
            }
        }
    }

    private var tradeListSection: some View {
        GlassGroup {
            LazyVStack(spacing: 12) {
                if repository.filteredTrades.isEmpty {
                    GlassCard(prominence: .subtle) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("暂无交易记录")
                                .font(.headline)
                            Text("点击右上角“新增”开始第一条复盘。")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                ForEach(repository.filteredTrades) { trade in
                    GlassCard(prominence: .regular, interactive: true) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(trade.symbol)
                                    .font(.headline)

                                FilterChip(
                                    title: trade.direction.rawValue,
                                    isSelected: true,
                                    action: {}
                                )
                                .allowsHitTesting(false)

                                Spacer()

                                Text(trade.pnl, format: .currency(code: "USD"))
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(trade.pnl >= 0 ? Color.green : Color.red)
                            }

                            HStack(spacing: 8) {
                                Text(trade.strategyTag)
                                    .font(.footnote.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .frame(height: 26)
                                    .modifier(PillSurfaceModifier(isSelected: true, interactive: false))

                                if !trade.mistakeTag.isEmpty {
                                    Text(trade.mistakeTag)
                                        .font(.footnote)
                                        .padding(.horizontal, 10)
                                        .frame(height: 26)
                                        .modifier(PillSurfaceModifier(isSelected: false, interactive: false))
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("开平时间：\(trade.openTime.formatted(date: .numeric, time: .shortened)) -> \(trade.closeTime.formatted(date: .omitted, time: .shortened))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                if !trade.notes.isEmpty {
                                    Text("备注：\(trade.notes)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                        .contentShape(RoundedRectangle(cornerRadius: style.cardCornerRadius, style: .continuous))
                    }
                    .onTapGesture {
                        editorSession = TradeEditorSession(existingTrade: trade)
                    }
                    .contextMenu {
                        Button("编辑") {
                            editorSession = TradeEditorSession(existingTrade: trade)
                        }
                        Button("删除", role: .destructive) {
                            Task {
                                do {
                                    try await repository.deleteTrade(id: trade.id)
                                } catch {
                                    activeErrorMessage = error.localizedDescription
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
