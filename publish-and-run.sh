#!/usr/bin/env bash
# HH500V 固件 —— 一键发布 + 触发编译（Linux / macOS / WSL）
#
# 前置：安装 git 和 GitHub CLI（gh），并执行 gh auth login
# 用法：在含 .github 的目录里执行  bash publish-and-run.sh
set -euo pipefail

command -v git >/dev/null || { echo "请先安装 git"; exit 1; }
command -v gh  >/dev/null || { echo "请先安装 GitHub CLI: https://cli.github.com/"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "请先运行: gh auth login"; exit 1; }
[ -f .github/workflows/build.yml ] || { echo "当前目录缺少 .github/workflows/build.yml"; exit 1; }

read -r -p "仓库名（回车用默认 hh500v-firmware）: " REPO_NAME
REPO_NAME="${REPO_NAME:-hh500v-firmware}"

[ -d .git ] || git init -b main
git add -A
git -c user.name=hh500v -c user.email=hh500v@local commit -m "HH500V ImmortalWrt build (24.10.6 + full)" || true

if gh repo view "$REPO_NAME" >/dev/null 2>&1; then
  USER_NAME=$(gh api user --jq .login)
  git remote remove origin 2>/dev/null || true
  git remote add origin "https://github.com/$USER_NAME/$REPO_NAME.git"
  git push -u origin main
else
  gh repo create "$REPO_NAME" --public --source=. --remote=origin --push
fi

gh workflow run build.yml -f version=24.10.6 -f plugins=full
sleep 8
gh run list --limit 3
echo
echo "打开上面的链接查看进度；成功后在该页面底部 Artifacts 下载 hh500v-24.10.6-full"
