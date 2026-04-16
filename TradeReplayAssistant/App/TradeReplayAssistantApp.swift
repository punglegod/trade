import SwiftData
import SwiftUI

@main
@MainActor
struct TradeReplayAssistantApp: App {
    private let modelContainer: ModelContainer

    @State private var repository: TradeRepository
    @State private var visualStyle = DefaultAppVisualStyle()

    init() {
        do {
            let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            let configurationName = isRunningTests ? "TradeReplayAssistantTests" : "TradeReplayAssistant"

            modelContainer = try ModelContainer(
                for: TradeRecord.self,
                configurations: ModelConfiguration(
                    configurationName,
                    isStoredInMemoryOnly: isRunningTests
                )
            )

            let localStore = LocalTradeStore(context: ModelContext(modelContainer))
            _repository = State(
                initialValue: TradeRepository(
                    localStore: localStore,
                    remoteDataSource: MockRemoteDataSource()
                )
            )
        } catch {
            fatalError("ModelContainer 初始化失败: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environment(repository)
                .environment(\.appVisualStyle, visualStyle)
                .task {
                    await repository.bootstrap()
                }
        }
        .modelContainer(modelContainer)
    }
}
