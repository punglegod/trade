# iOS Cloud Build (GitHub Actions)

这个仓库已经配置了 iOS 云构建：

- Workflow 文件：`.github/workflows/ios-ci.yml`
- 触发方式：
  - push 到 `main` / `master` / `develop`
  - 对这些分支发起 PR
  - 在 GitHub Actions 页面手动触发（`workflow_dispatch`）

## 做了什么

流水线会在 GitHub 的 `macos-latest` runner 上执行：

1. Checkout 代码
2. 切换到最新稳定版 Xcode
3. 输出 Xcode / SDK 信息
4. 解析 Swift Package 依赖
5. 自动选择可用 iPhone 模拟器
6. 执行 `xcodebuild build`（关闭 code signing）
7. 执行 `xcodebuild test`
8. 上传 `xcresult` 与 `build.log` 作为 artifacts

## 你现在怎么用

1. 把本地代码推到 GitHub 仓库。
2. 打开仓库的 **Actions** 页面。
3. 找到 **iOS CI**，查看每次构建和测试结果。
4. 失败时下载 artifacts：
   - `ios-test-results`
   - `ios-build-log`

## 常见问题

- `No available iPhone simulator found`：
  GitHub runner 异常或镜像变更，重跑一次通常可恢复。

- 编译错误涉及新 SDK API：
  目前 workflow 已使用最新稳定 Xcode。若你需要指定版本，可在 `ios-ci.yml` 改 `xcode-version`。

## 下一步（可选）

如果你要自动发 TestFlight，需要额外加“签名与发布”workflow（证书、描述文件、App Store Connect API Key secrets）。
