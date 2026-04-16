#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT_PATH="$ROOT_DIR/TradeReplayAssistant.xcodeproj"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild 未安装。请先安装 Xcode（App Store）并完成首次启动。"
  exit 1
fi

if [ ! -d "$PROJECT_PATH" ]; then
  echo "未找到工程: $PROJECT_PATH"
  exit 1
fi

echo "==> 列出工程与 scheme"
xcodebuild -list -project "$PROJECT_PATH"

echo "==> 打开工程"
open "$PROJECT_PATH"
