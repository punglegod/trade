import SwiftUI

struct WeeklyReportView: View {
    @Environment(TradeRepository.self) private var repository
    @Environment(\.appVisualStyle) private var style

    private var report: WeeklyReport {
        repository.weeklyReport()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: style.sectionSpacing) {
                headerCard
                summaryCards
                tagSection(title: "本周做得好的点", items: report.goodPractices)
                tagSection(title: "需要改进", items: report.improvementAreas)
                actionSection
            }
            .padding(.horizontal, style.screenHorizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(style.screenBackground.ignoresSafeArea())
        .navigationTitle("周报")
    }

    private var headerCard: some View {
        GlassCard(prominence: .strong) {
            VStack(alignment: .leading, spacing: 8) {
                Text("周复盘摘要")
                    .font(.headline)

                Text(
                    "区间：\(report.weekInterval.start.formatted(date: .abbreviated, time: .omitted)) - \(report.weekInterval.end.formatted(date: .abbreviated, time: .omitted))"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)

                Text("总盈亏 \(report.summary.totalPnL, format: .currency(code: "USD"))")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(report.summary.totalPnL >= 0 ? Color.green : Color.red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var summaryCards: some View {
        GlassGroup {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                summaryCard(title: "交易数", value: "\(report.summary.totalTrades)")
                summaryCard(title: "胜率", value: report.summary.winRate.formatted(.percent.precision(.fractionLength(1))))
                summaryCard(title: "盈亏比", value: report.summary.profitFactor.formatted(.number.precision(.fractionLength(2))))
                summaryCard(title: "最大回撤", value: report.summary.maxDrawdown.formatted(.currency(code: "USD")))
            }
        }
    }

    private func tagSection(title: String, items: [String]) -> some View {
        GlassCard(prominence: .regular) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        Text(item)
                            .font(.footnote)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 10)
                            .frame(height: 30)
                            .modifier(PillSurfaceModifier(isSelected: false, interactive: false))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var actionSection: some View {
        GlassCard(prominence: .regular) {
            VStack(alignment: .leading, spacing: 10) {
                Text("下周行动项")
                    .font(.headline)

                ForEach(Array(report.nextWeekActions.enumerated()), id: \.offset) { index, action in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(style.accentColor)

                        Text(action)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func summaryCard(title: String, value: String) -> some View {
        GlassCard(prominence: .subtle) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
