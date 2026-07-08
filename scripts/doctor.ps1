# doctor.ps1 — Claude Code 環境の機体パリティ監査
# 目的: Desktop / laptop 等の複数機体で「同じ設定で動いているか」を1コマンドで検査する。
#       (将来 dotfiles repo の bootstrap に同梱予定 — docs/config-sync-plan.md 参照)
# 使い方: powershell -ExecutionPolicy Bypass -File .\doctor.ps1
# 終了コード: FAIL の件数

$ErrorActionPreference = 'Continue'
$script:Fails = 0
$script:Warns = 0

function Check([string]$Name, [bool]$Ok, [string]$Detail = '', [switch]$WarnOnly) {
  if ($Ok) { Write-Host ("  PASS  {0}" -f $Name) -ForegroundColor Green }
  elseif ($WarnOnly) { $script:Warns++; Write-Host ("  WARN  {0}  {1}" -f $Name, $Detail) -ForegroundColor Yellow }
  else { $script:Fails++; Write-Host ("  FAIL  {0}  {1}" -f $Name, $Detail) -ForegroundColor Red }
}

Write-Host "== Claude Code parity doctor ($env:COMPUTERNAME / $env:USERNAME) =="

# --- 1. コアツール ---
Write-Host "`n[core tools]"
$claudeV = (& claude --version 2>$null) -join ''
Check "claude CLI" ($claudeV -match '\d+\.\d+') "not found"
if ($claudeV -match '(\d+)\.(\d+)\.(\d+)') {
  $ok = ([int]$Matches[1] -gt 2) -or (([int]$Matches[1] -eq 2) -and (([int]$Matches[2] -gt 1) -or ([int]$Matches[3] -ge 78)))
  Check "claude >= 2.1.78 (StopFailure hook)" $ok "found: $claudeV"
}
Check "node" ([bool](Get-Command node -ErrorAction SilentlyContinue)) "not in PATH"
Check "git"  ([bool](Get-Command git  -ErrorAction SilentlyContinue)) "not in PATH"
Check "gh (auth)" ((& gh auth status 2>&1) -join '' -match 'Logged in') "gh auth login が必要" -WarnOnly
Check "codex CLI" ([bool](Get-Command codex -ErrorAction SilentlyContinue)) "codex-handoff の退避先に必要" -WarnOnly
Check "codex login (~/.codex/auth.json)" (Test-Path (Join-Path $HOME '.codex\auth.json')) "codex login が必要" -WarnOnly
Check "gitleaks" ([bool](Get-Command gitleaks -ErrorAction SilentlyContinue)) "pre-commit の深層スキャンが skip になる" -WarnOnly
Check "7-Zip" (Test-Path 'C:\Program Files\7-Zip\7z.exe') "vault バックアップに必要" -WarnOnly

# --- 2. ~/.claude 配布物(agent-workflow の install 済みか) ---
Write-Host "`n[~/.claude components]"
$dotc = Join-Path $HOME '.claude'
foreach ($d in @('agents', 'commands', 'rules')) {
  Check "~/.claude/$d" ((Test-Path (Join-Path $dotc $d)) -and ((Get-ChildItem (Join-Path $dotc $d) -ErrorAction SilentlyContinue).Count -gt 0)) "agent-workflow の install 未実施?"
}
foreach ($f in @('agents\reviewer.md', 'commands\handoff.md', 'commands\review-diff.md', 'rules\agent-workflow.md', 'rules\output-style.md')) {
  Check "  $f" (Test-Path (Join-Path $dotc $f)) "missing"
}

# --- 3. codex-handoff(導入機体のみ。未導入は WARN) ---
Write-Host "`n[codex-handoff]"
$chScripts = Join-Path $dotc 'scripts\codex-handoff\guard.mjs'
$chConfig  = Join-Path $dotc 'codex-handoff\config.json'
$installed = Test-Path $chScripts
Check "scripts/codex-handoff/guard.mjs" $installed "未導入(docs/codex-handoff-plan.md 参照)" -WarnOnly
if ($installed) {
  Check "codex-handoff/config.json" (Test-Path $chConfig) "config 欠落"
  $settings = Join-Path $dotc 'settings.json'
  $wired = (Test-Path $settings) -and ((Get-Content $settings -Raw -ErrorAction SilentlyContinue) -match 'codex-handoff[/\\]guard\.mjs')
  Check "settings.json に guard.mjs hook 配線" $wired "hooks 未登録"
  if ($wired) {
    $raw = Get-Content $settings -Raw
    $wrongUser = ($raw -match 'Users[/\\](?!' + [regex]::Escape($env:USERNAME) + ')[A-Za-z0-9_]+[/\\]\.claude')
    Check "hook パスがこの機体のユーザー名" (-not $wrongUser) "他機体のパスをコピーした可能性(要修正)"
  }
}

# --- 4. Obsidian vault(存在する機体のみ検査) ---
Write-Host "`n[obsidian vault]"
$vaultCandidates = @(
  (Join-Path $HOME 'Documents\Obsidian\obsidian-vault'),
  (Join-Path $HOME 'Obsidian\obsidian-vault')
)
$vault = $vaultCandidates | Where-Object { Test-Path (Join-Path $_ '.git') } | Select-Object -First 1
if ($vault) {
  Write-Host "  vault: $vault"
  $hp = (git -C $vault config --local core.hooksPath 2>$null)
  Check "core.hooksPath = tools/git-hooks" ($hp -eq 'tools/git-hooks') "found: '$hp' — 共有 pre-commit が無効"
  $ac = (git -C $vault config --local core.autocrlf 2>$null)
  Check "core.autocrlf = false" ($ac -eq 'false') "found: '$ac'"
  Check "tools/git-hooks/pre-commit 実在" (Test-Path (Join-Path $vault 'tools\git-hooks\pre-commit')) "pull 不足?"
  $bk = Get-ScheduledTask -TaskName 'obsidian-vault-backup' -ErrorAction SilentlyContinue
  Check "週次バックアップタスク" ($null -ne $bk) "tools/backup/backup-vault.ps1 -Register" -WarnOnly
  $wc = Get-ScheduledTask -TaskName 'obsidian-weekly-classify' -ErrorAction SilentlyContinue
  Check "週次分類タスク" ($null -ne $wc) "tools/weekly-classify/run-weekly-classify.ps1 -Register" -WarnOnly
} else {
  Write-Host "  (vault なし — skip)"
}

# --- summary ---
Write-Host ("`n== result: {0} FAIL / {1} WARN ==" -f $script:Fails, $script:Warns) -ForegroundColor $(if ($script:Fails -gt 0) { 'Red' } elseif ($script:Warns -gt 0) { 'Yellow' } else { 'Green' })
exit $script:Fails
