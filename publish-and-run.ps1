# HH500V 固件 —— 一键发布 + 触发编译（Windows PowerShell）
#
# 前置（只需一次）：
#   1) 安装 Git for Windows:  https://git-scm.com/download/win
#   2) 安装 GitHub CLI:       https://cli.github.com/   (或 winget install GitHub.cli)
#   3) 登录:                  gh auth login
#
# 用法：在本文件所在目录（含 .github 的文件夹）右键 →「在终端中打开」，然后：
#   powershell -ExecutionPolicy Bypass -File .\publish-and-run.ps1
#
# 它会：建公开仓库 -> 推代码 -> 触发 24.10.6 + full 构建 -> 打印运行链接

$ErrorActionPreference = 'Stop'

function Fail($msg) { Write-Host "`n[失败] $msg" -ForegroundColor Red; exit 1 }

Write-Host "=== 检查依赖 ===" -ForegroundColor Cyan
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Fail "没装 Git，先装 https://git-scm.com/download/win 并重开终端" }
if (-not (Get-Command gh  -ErrorAction SilentlyContinue)) { Fail "没装 GitHub CLI，运行: winget install GitHub.cli 然后重开终端" }

$authOk = (gh auth status 2>&1 | Out-String)
if ($authOk -match 'not logged') { Fail "还没登录，先运行: gh auth login" }

# 必须在这个目录（含 .github/workflows/build.yml）
if (-not (Test-Path '.github\workflows\build.yml')) { Fail "当前目录没有 .github\workflows\build.yml；请先进入解压后的 hh500v-firmware 文件夹" }

$repoName = Read-Host "仓库名（回车用默认 hh500v-firmware）"
if ([string]::IsNullOrWhiteSpace($repoName)) { $repoName = 'hh500v-firmware' }

Write-Host "`n=== 初始化本地仓库 ===" -ForegroundColor Cyan
if (-not (Test-Path '.git')) {
    git init -b main | Out-Null
}
git add -A
git -c user.name="hh500v" -c user.email="hh500v@local" commit -m "HH500V ImmortalWrt build (24.10.6 + full)" 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "(没有新改动，继续)" -ForegroundColor DarkGray }

Write-Host "`n=== 创建 GitHub 仓库并推送 ===" -ForegroundColor Cyan
$existing = gh repo view "$repoName" --json name 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "仓库已存在，直接推送..." -ForegroundColor Yellow
    $user = (gh api user --jq .login)
    git remote remove origin 2>$null
    git remote add origin "https://github.com/$user/$repoName.git"
    git push -u origin main
} else {
    gh repo create $repoName --public --source=. --remote=origin --push
}

Write-Host "`n=== 触发编译 (24.10.6 + full) ===" -ForegroundColor Cyan
gh workflow run build.yml -f version=24.10.6 -f plugins=full

Start-Sleep -Seconds 8
Write-Host "`n=== 当前运行 ===" -ForegroundColor Green
gh run list --limit 3
$url = gh run list --limit 1 --json url --jq '.[0].url'
Write-Host "`n打开查看进度：$url" -ForegroundColor Green
Write-Host "编译约 60~120 分钟；成功后在该页面底部 Artifacts 下载 hh500v-24.10.6-full" -ForegroundColor Green
Write-Host "`n提示：若 Backport / Build 失败，把失败步骤的最后 40 行日志发我。" -ForegroundColor Yellow
