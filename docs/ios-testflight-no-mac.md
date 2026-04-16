# 没有 Mac 也能发 TestFlight（本仓库方案）

你可以直接用 GitHub Actions 的 macOS runner 完成打包和上传，不需要本地 Mac。

## 已配置

- CI 构建测试：`.github/workflows/ios-ci.yml`
- TestFlight 发布：`.github/workflows/ios-testflight.yml`

`ios-testflight.yml` 触发方式：
- 手动触发（Actions -> iOS Release to TestFlight -> Run workflow）
- 推送 tag（如 `v0.1.1`）

## 你要准备的 Secrets（GitHub 仓库 Settings -> Secrets and variables -> Actions）

必填：

1. `APPLE_TEAM_ID`
2. `APP_BUNDLE_ID`
3. `BUILD_CERTIFICATE_BASE64`（Apple Distribution 证书 `.p12` 的 base64）
4. `BUILD_CERTIFICATE_PASSWORD`（导出 `.p12` 时的密码）
5. `BUILD_PROVISION_PROFILE_BASE64`（App Store 描述文件 `.mobileprovision` 的 base64）
6. `BUILD_PROVISION_PROFILE_NAME`（描述文件名字，和 Apple Developer 后台一致）
7. `APPSTORE_CONNECT_ISSUER_ID`
8. `APPSTORE_CONNECT_KEY_ID`
9. `APPSTORE_CONNECT_PRIVATE_KEY`（`.p8` 文件内容原文，不是 base64）

## Windows 下生成 base64

PowerShell：

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\dist.p12"))
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\appstore.mobileprovision"))
```

把输出内容分别粘贴到：
- `BUILD_CERTIFICATE_BASE64`
- `BUILD_PROVISION_PROFILE_BASE64`

## App Store Connect API Key（.p8）

在 App Store Connect -> Users and Access -> Keys 创建 API Key 后：
- `Issuer ID` -> `APPSTORE_CONNECT_ISSUER_ID`
- `Key ID` -> `APPSTORE_CONNECT_KEY_ID`
- 下载的 `.p8` 文件全文 -> `APPSTORE_CONNECT_PRIVATE_KEY`

## 发布流程

1. 先确保 `ios-ci.yml` 绿灯
2. 在仓库打 tag：`v0.1.1`（或手动触发 workflow）
3. 打开 Actions 运行 `iOS Release to TestFlight`
4. 成功后到 App Store Connect -> TestFlight 查看构建

## 常见失败点

1. `No signing certificate ...`：`BUILD_CERTIFICATE_BASE64` 或密码错误
2. `No profiles for ...`：`APP_BUNDLE_ID` 与描述文件不匹配
3. `altool upload failed`：`Issuer ID / Key ID / p8` 不匹配或过期
4. `bundle identifier mismatch`：工程中的 Bundle ID 与 secret 不一致

## 注意

- 你之前泄露过 GitHub PAT，建议立即在 GitHub 里撤销并重建。

