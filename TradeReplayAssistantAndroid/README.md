# TradeReplayAssistant Android

Jetpack Compose MVP（中文界面）：
- 交易记录：新增、删除、按标的/策略筛选
- 统计看板：近7天、近30天、年内
- 周报：本周总结、改进行动
- 视觉：玻璃感卡片 + 药丸组件（Chip/按钮/分段）

## 打开方式

1. 用 Android Studio 打开 `TradeReplayAssistantAndroid` 目录。
2. 同步 Gradle。
3. 运行 `app` 模块。

## 目录

- `app/src/main/java/com/punglegod/trade/data`：仓储与存储
- `app/src/main/java/com/punglegod/trade/domain`：领域模型与统计/周报服务
- `app/src/main/java/com/punglegod/trade/ui`：组件、页面、主题
- `app/src/test/java/com/punglegod/trade`：单元测试
