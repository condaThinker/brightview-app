#!/usr/bin/env bash
# 一键开源发布：建公开仓库 → 推送 → 打 tag 触发 APK 构建
#
# 用法：
#   ./scripts/publish.sh                 # 仓库名默认 brightview-app
#   ./scripts/publish.sh my-repo-name    # 自定义仓库名
#
# 前置条件：
#   1. 已安装 gh（GitHub CLI）
#   2. 已登录：gh auth login
#   3. 在仓库根目录执行

set -euo pipefail

REPO_NAME="${1:-brightview-app}"
DESCRIPTION="离线优先的每日实修打卡 App：早起户外打卡、睡前五问、145 集熏习课表。反连续签到、反排行榜。"

if ! command -v gh >/dev/null 2>&1; then
  echo "找不到 gh，请先安装 GitHub CLI：https://cli.github.com/"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "尚未登录 GitHub，请先执行："
  echo "    gh auth login"
  exit 1
fi

echo "==> 当前账号：$(gh api user --jq .login)"

if [ ! -d .git ]; then
  echo "==> 初始化仓库"
  git init -q
  git add -A
  git commit -q -m "feat: 悦为因实修 App 首个可安装版本" || true
fi

if git remote get-url origin >/dev/null 2>&1; then
  echo "==> 已存在 origin：$(git remote get-url origin)"
else
  echo "==> 创建公开仓库 $REPO_NAME"
  gh repo create "$REPO_NAME" --public --source=. --remote=origin \
    --description "$DESCRIPTION" --push
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "==> 推送 $BRANCH"
git push -u origin "$BRANCH"

echo "==> 打 tag v0.6.0（会触发 GitHub Actions 构建 APK 并附加到 Release）"
git tag -f v0.6.0
git push -f origin v0.6.0

echo ""
echo "完成。接下来："
echo "  1. 打开 Actions 看构建进度：gh run watch"
echo "  2. APK 会在 Release 页：gh release view v0.6.0 --web"
