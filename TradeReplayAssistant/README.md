# TradeReplayAssistant (iOS SwiftUI MVP)

这是一个按以下目标实现的 MVP：
- 交易记录（新增/编辑/删除/筛选）
- 统计看板（近 7 天 / 30 天 / 年内）
- 周报生成（做得好、待改进、下周行动）
- 视觉风格：Liquid Glass + 药丸组件（iOS 26+ 原生，iOS 17-25 自动降级）

## 目录结构

- `App/`: App 入口与 Tab 容器
- `Domain/`: 领域模型与统计窗口
- `Data/`: SwiftData 持久化、Mock API、仓储
- `Services/`: 周报与统计计算
- `DesignSystem/`: 视觉 Token、Glass 组件、Pill 组件
- `Features/`: 记录页、统计页、周报页
- `Tests/`: 核心逻辑测试样例

## 运行要求

- Xcode 18+（建议，支持 iOS 26 SDK）
- 最低部署：iOS 17
- 推荐测试设备：
  - iOS 26 模拟器（验证原生 Liquid Glass）
  - iOS 17/18 模拟器（验证降级材质样式）

## 快速开始（macOS）

1. 进入仓库根目录并双击打开 `TradeReplayAssistant.xcodeproj`。
2. 选择 Scheme：`TradeReplayAssistant`，目标模拟器选择 iPhone。
3. 直接运行 `Cmd + R`。
4. 运行测试使用 `Cmd + U`（包含 `ReportService` 与 `TradeRepository` 基础测试）。

可选：执行 `TradeReplayAssistant/scripts/bootstrap_macos.sh` 自动列出工程并打开 Xcode。

## 云端构建与发布（无 Mac）

- CI 构建测试说明：`docs/ios-cloud-build.md`
- TestFlight 云端发布说明：`docs/ios-testflight-no-mac.md`

## 关键实现说明

- 数据层采用 `TradeDataSource` 协议，当前实现为 `MockRemoteDataSource`。
- 同步策略为 LWW（Last Write Wins），冲突数量会在 UI 上提示。
- 所有筛选器、主操作和标签均使用 Capsule（药丸）元素。
- iOS 26+ 使用 `.glassEffect(...)` / `GlassEffectContainer` / `.buttonStyle(.glass)`。
- iOS 17-25 自动回退到 `.ultraThinMaterial` + Capsule/RoundedRectangle。
