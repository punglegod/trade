import SwiftUI

struct StatsView: View {
    @Environment(TradeRepository.self) private var repository
    @Environment(\.appVisualStyle) private var style

    @State private var selectedRange: StatsRangeWindow = .last7Days

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: style.sectionSpacing) {
                PillSegmentedControl(
                    options: StatsRangeWindow.allCases,
                    selection: $selectedRange,
                    title: { $0.rawValue }
                )

                metricsGrid
                strategyPanel
            }
            .padding(.horizontal, style.screenHorizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(style.screenBackground.ignoresSafeArea())
        .navigationTitle("统计")
    }

    private var metricsGrid: some View {
        let summary = repository.summary(for: selectedRange)

        return GlassGroup {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                metricCard(title: "交易数", value: "\(summary.totalTrades)")
                metricCard(title: "胜率", value: summary.winRate.formatted(.percent.precision(.fractionLength(1))))
                metricCard(title: "总盈亏", value: summary.totalPnL.formatted(.currency(code: "USD")))
                metricCard(title: "最大回撤", value: summary.maxDrawdown.formatted(.currency(code: "USD")))
                metricCard(title: "平均盈利", value: summary.averageWin.formatted(.currency(code: "USD")))
                metricCard(title: "平均亏损", value: summary.averageLoss.formatted(.currency(code: "USD")))
            }
        }
    }

    private var strategyPanel: some View {
        GlassCard(prominence: .regular) {
            VStack(alignment: .leading, spacing: 12) {
                Text("策略热度")
                    .font(.headline)

                let topStrategies = strategyBreakdown(prefix: 6)
                if topStrategies.isEmpty {
                    Text("当前区间暂无可统计数据")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(topStrategies, id: \.0) { item in
                            HStack {
                                Text(item.0)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(item.1) 笔")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 32)
                            .modifier(PillSurfaceModifier(isSelected: false, interactive: false))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func metricCard(title: String, value: String) -> some View {
        GlassCard(prominence: .subtle) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.weight(.semibold))
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func strategyBreakdown(prefix: Int) -> [(String, Int)] {
        let interval = selectedRange.interval()
        let source = repository.trades
            .filter { !$0.isDeleted && interval.contains($0.closeTime) }

        let counts = source.reduce(into: [String: Int]()) { partial, trade in
            partial[trade.strategyTag, default: 0] += 1
        }

        return counts
            .sorted {
                if $0.value == $1.value {
                    return $0.key < $1.key
                }
                return $0.value > $1.value
            }
            .prefix(prefix)
            .map { ($0.key, $0.value) }
    }
}
