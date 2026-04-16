# Xcode 接入说明

当前目录已包含可直接打开的 Xcode 工程：`TradeReplayAssistant.xcodeproj`。

建议步骤：

1. 在 macOS 上打开 `TradeReplayAssistant.xcodeproj`。
2. 先执行一次 `Product > Clean Build Folder`，再 `Cmd + R`。
3. 在 iOS 26 模拟器验证原生 Liquid Glass 效果。
4. 在 iOS 17/18 模拟器验证降级样式（`.ultraThinMaterial + Capsule/RoundedRectangle`）。
5. 用 `Cmd + U` 跑测试 target：`TradeReplayAssistantTests`。

可选：运行 `TradeReplayAssistant/scripts/bootstrap_macos.sh` 自动检查并打开工程。
