import SwiftUI

struct AppShellView: View {
    @State private var selectedTab: AppTab = .records

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                RecordsView()
            }
            .tabItem {
                Label(AppTab.records.title, systemImage: AppTab.records.systemImage)
            }
            .tag(AppTab.records)

            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label(AppTab.stats.title, systemImage: AppTab.stats.systemImage)
            }
            .tag(AppTab.stats)

            NavigationStack {
                WeeklyReportView()
            }
            .tabItem {
                Label(AppTab.report.title, systemImage: AppTab.report.systemImage)
            }
            .tag(AppTab.report)
        }
    }
}
