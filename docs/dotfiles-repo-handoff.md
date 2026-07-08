# HANDOFF: dotfiles-repo — `~/.claude` 横断同期のアンブレラ新設

> この文書だけで作業が完了できるように書いてある。特定の会話・セッションへの参照は含まない。
> 実装後は本リポジトリ（`claude-code-agent-workflow`）の `/review-diff` で検収する運用。

## 1. 目的

Claude Code の設定 `~/.claude/` を **2台の Windows 機（Desktop / Laptop）で「同じ」に保つ**ための専用 dotfiles リポジトリ（アンブレラ）と、1発で展開する bootstrap インストーラを新設する。Obsidian 等の知識データとは独立した「機体設定の横断レイヤー」を確立する。

- Desktop ユーザープロファイル: `C:\Users\User`
- Laptop ユーザープロファイル: `C:\Users\sawa3`
- **機体固有の絶対パスを設定ファイルに直書きしない**（丸ごとコピーだと相手機で壊れる）。`$env:USERPROFILE` 展開かリポジトリ相対で可搬にする。

## 2. 背景・調査結果（実測。推測は「推測」と明記）

### 2.1 現在の同期状況（事実）
- `~/.claude` 自体は **git 管理されていない**（`.git` 無し。マシンローカル）。
- 既に GitHub 同期されている関連リポジトリ（すべて private、GitHub アカウント `0x000x7f`）:
  - `claude-code-agent-workflow` — agents/commands/rules の source of truth（本リポジトリ）。
  - `obsidian-vault` — 知識ベース＋vault tools（Obsidian 依存）。
  - `zenn-content` — 記事。
- 現状 Laptop に届く `~/.claude` 設定は **`agents` / `commands` / `rules` のみ**（`claude-code-agent-workflow/claude/` を各機へ Copy-Item する運用）。それ以外（settings.json / skills / hooks / codex-handoff / MCP / plugins / 記憶層）は**未カバー**。

### 2.2 `~/.claude` トップレベルの実体（Desktop 実測）
```
CLAUDE.md  agents  backups  cache  codex-handoff  commands  downloads
history.jsonl  hooks  ide  mcp-needs-auth-cache.json  plans  plugins
policy-limits.json  projects  remote-settings.json  rules  scripts
session-env  sessions  settings.json  settings.json.bak  shell-snapshots
skills  tasks
```

### 2.3 配布スクリプトの現状（事実）
- `claude-code-agent-workflow/scripts/` には **`doctor.ps1`（検証専用）しかない**。実際に repo→`~/.claude` へ配る **deploy/install スクリプトは未整備**（現状は手動 Copy-Item 相当）。
- `doctor.ps1` は `~/.claude/{agents,commands,rules}` の存在と、`agents\reviewer.md` `commands\handoff.md` `commands\review-diff.md` `rules\agent-workflow.md` `rules\output-style.md` の実在を検査する。

### 2.4 settings.json の機体固有パス（事実・重要）
`~/.claude/settings.json` 内に機体固有の絶対パス直書きが **1種類**ある:
```
C:/Users/User/.claude/scripts/codex-handoff/guard.mjs
```
これは hooks（SessionStart / Stop / StopFailure / UserPromptSubmit）の command に登場する。**丸ごとコピーすると Laptop（C:\Users\sawa3）で解決できず hook が壊れる** → `$env:USERPROFILE` 展開でマージ生成する対象。
（他の hooks は `lean-ctx hook ...` の PATH 解決コマンドで機体非依存。）

### 2.5 skills の内訳（要トリアージ）
`~/.claude/skills/`: `cross-model-introspect` `gpt` `lean-ctx` `memory-dream` `modern-web-guidance` `zenn`
- `lean-ctx` は **npm 自動導入**（外部インストール＝C 分類）。git に含めない。
- 残りは自作の可能性が高い（A 分類＝配布）。**実装前に各 SKILL.md 冒頭を見て「自作か外部か」を確定**すること。

### 2.6 codex-handoff の内訳（事実）
- `~/.claude/scripts/codex-handoff/`: `guard.mjs` `launch.mjs` `lib.mjs` `resume.mjs`（=コード。A 分類＝配布）
- `~/.claude/codex-handoff/`: `README.md` `SHARE-codex-handoff.md` `config.json`（配布候補）＋ `logs/` `state.json` `usage-cache.json`（=実行時状態。B 分類＝除外）
- `config.json` に機体固有値が無いか実装時に確認。あれば `$env:USERPROFILE` 化。

## 3. 設計・方針

### 3.1 3分類（`~/.claude` 実体ベースの棚卸し）
| 分類 | 実体 | 扱い |
|---|---|---|
| **A. 同一化（版管理して配布）** | `CLAUDE.md`, `agents/`, `commands/`, `rules/`, 自作 `skills/`, `hooks/`(ファイル), `scripts/codex-handoff/*.mjs`, `codex-handoff/{README,SHARE,config.json}`, `settings.json` の可搬部 | dotfiles repo に置き、`install.ps1` で各機へ展開 |
| **B. 機体ローカル状態・秘密（共有しない）** | `projects/`, `sessions/`, `history.jsonl`, `cache/`, `backups/`, `shell-snapshots/`, `session-env/`, `plans/`, `tasks/`, `downloads/`, `*-cache.json`, `policy-limits.json`, `remote-settings.json`, `mcp-needs-auth-cache.json`, `settings.json.bak`, `codex-handoff/{logs,state.json,usage-cache.json}`, `ide/`, MCP/Codex 認証 | `.gitignore` で除外。**絶対にコミットしない**（状態混線・秘密漏洩） |
| **C. 外部インストール（ファイル共有では揃わない）** | MCP サーバー群, `plugins/`(marketplace), Codex CLI, `skills/lean-ctx`(npm), Node.js | bootstrap のマニフェスト（導入手順）で揃える。認証は各機で手動 |

### 3.2 リポジトリ境界（決定事項）
- **dotfiles repo（新設・アンブレラ）**: `~/.claude` 可搬設定の全体 ＋ bootstrap インストーラ。A の大半 ＋ C の導入手順。
- **`claude-code-agent-workflow`（既存・コンポーネント）**: agents/commands/rules の **source of truth のまま**。dotfiles は**重複保持せず、bootstrap から clone/pull して呼び込む（参照方式＝疎結合）**。submodule は使わない（取り回しコスト回避）。
- 両者の README に相互関係を明記する。

### 3.3 memory 層（`projects/*/memory`）の扱い（決定）
- **B 分類（機体ローカル・除外）が既定**。個人 recall であり機体ローカル状態のため同期しない。
- ただし「両機で共有したい規約」に育ったものは、**memory から `rules/` 層へ昇格**して配布する（前例あり: 出力様式ルールを `claude/rules/output-style.md` へ昇格）。この運用ルールを dotfiles README に明記する。

### 3.4 settings.json の合成方針（重要）
丸ごと上書きしない。**テンプレート＋機体固有値の展開でマージ生成**する:
- リポジトリには `settings.template.json`（機体固有パスを `%USERPROFILE%` 等プレースホルダにしたもの）を置く。
- `install.ps1` が既存 `settings.json` を読み、テンプレートの可搬部（hooks 配線・enableWorkflows 等）を**マージ**し、プレースホルダを実機の `$env:USERPROFILE` に展開して書き戻す。
- 既存の機体ローカル値（policy 等）は保持する。

## 4. 対象ファイル

### 新規作成（dotfiles repo 側 — 新規リポジトリのワークツリー）
- `install.ps1` — bootstrap 本体（A 展開 ＋ settings.json マージ ＋ C マニフェスト実行 ＋ agent-workflow を clone/pull して呼び込み）
- `README.md` — アンブレラの説明。agent-workflow をコンポーネントとして参照する旨、memory→rules 昇格運用、B は配らない旨
- `dotclaude/` — A 分類の実体（`CLAUDE.md`, 自作 `skills/`, `scripts/codex-handoff/*.mjs`, `codex-handoff/{README,SHARE,config.json}`, `hooks/` 等）。**agents/commands/rules は置かない**（agent-workflow が持つ）
- `settings.template.json` — 上記 3.4
- `manifest.md`（または `bootstrap-manifest.md`）— C 分類の導入手順（MCP 一覧、plugins、Codex CLI、Node、lean-ctx npm、各認証の手動手順）
- `.gitignore` — B 分類を全除外（下記「制約」参照）

### 変更してよい（本リポジトリ側 = `claude-code-agent-workflow`）
- `README.md` — 「本 repo は dotfiles アンブレラの1コンポーネント。agents/commands/rules の source of truth はここ」を追記
- `docs/config-sync-plan.md` — 実装済みに合わせて追記（計画→実装のステータス更新）
- 必要なら `scripts/doctor.ps1` — dotfiles 展開物（settings.json の guard.mjs 配線、自作 skills、codex-handoff）のパリティ検査を追加

### 読むべき参照
- `claude-code-agent-workflow/docs/config-sync-plan.md`（A/B/C・repo境界・bootstrap の元計画）
- `~/.claude/settings.json`（hooks 配線の実体）
- `~/.claude/codex-handoff/README.md`（codex-handoff の役割）

## 5. 制約・禁止事項

- **秘密・状態を絶対にコミットしない**: B 分類（`projects/ sessions/ history.jsonl cache/ backups/ shell-snapshots/ session-env/ plans/ tasks/ downloads/ *-cache.json policy-limits.json remote-settings.json mcp-needs-auth-cache.json settings.json.bak codex-handoff/{logs,state.json,usage-cache.json} ide/`）と、MCP 認証 / `~/.codex/auth.json` / PAT / トークン。`.gitignore` を allowlist 寄り（既定除外）で厳格に。
- **機体固有絶対パスの直書き禁止**: `C:\Users\User\...` を配布物に入れない。`$env:USERPROFILE` / `%USERPROFILE%` / リポジトリ相対に。
- **settings.json を丸ごと上書きしない**（マージ生成）。
- **agents/commands/rules を dotfiles に複製しない**（source of truth は agent-workflow。参照方式で呼び込む）。
- **install.ps1 は冪等**にする（複数回実行しても壊れない。既存を退避 or マージ）。破壊的操作の前にバックアップ（例: `settings.json` → `.bak`）。
- **振る舞いは変えない**: 既存 hooks の意味・発火条件を変更しない。配線先パスの可搬化のみ。
- PowerShell 5.1 前提の罠に注意: 日本語コメント入り `.ps1` は **BOM 必須**、`$ErrorActionPreference='Stop'` 下で native コマンドの stderr が例外化する（git 等は `cmd /c` 経由か、native 呼び出し前に `Continue` へ）。

## 6. テストコマンド（検証と期待結果）

```powershell
# a. install.ps1 は冪等（2回流して2回目もエラー0・差分が増えない）
pwsh -File .\install.ps1 ; pwsh -File .\install.ps1   # 期待: 両方とも成功終了

# b. settings.json のマージ後、機体固有パスが実機の USERPROFILE に展開されている
Select-String -Path "$env:USERPROFILE\.claude\settings.json" -Pattern 'guard\.mjs'
#   期待: パスが現在機の $env:USERPROFILE 配下を指す（別機のプロファイル名が残っていない）

# c. 秘密・状態が追跡対象に混入していないこと（dotfiles repo のワークツリーで）
git -C <dotfiles> status --porcelain | Select-String 'projects/|sessions/|history\.jsonl|auth|cache/'
#   期待: 出力なし（.gitignore で除外済み）

# d. パリティ検査（agent-workflow）
pwsh -File "$env:USERPROFILE\claude-code-agent-workflow\scripts\doctor.ps1"
#   期待: FAIL 0（WARN は環境依存で許容）

# e. 展開後、Claude Code が rules を読める（ハーネスが ~/.claude/rules/*.md を自動読込）
Test-Path "$env:USERPROFILE\.claude\rules\output-style.md"   # 期待: True
```

## 7. 完了条件（チェックリスト）

- [ ] dotfiles private repo（`0x000x7f/...`）が作成され、`install.ps1` / `README.md` / `dotclaude/`（A分類）/ `settings.template.json` / `manifest.md` / `.gitignore` を含む
- [ ] `.gitignore` が B 分類・秘密を全除外し、`git status` に状態/秘密が一切出ない（テスト c 合格）
- [ ] `install.ps1` が冪等で、A の展開 ＋ settings.json のマージ展開 ＋ agent-workflow の clone/pull 呼び込み ＋ C マニフェスト提示 を行う（テスト a/b 合格）
- [ ] settings.json の機体固有パスが `$env:USERPROFILE` 展開でマージされ、丸ごと上書きしていない（テスト b 合格）
- [ ] agents/commands/rules を dotfiles に複製していない（agent-workflow 参照方式）
- [ ] skills が自作/外部でトリアージされ、自作のみ配布・lean-ctx 等 npm は manifest 手順
- [ ] `claude-code-agent-workflow/README.md` と dotfiles `README.md` が相互参照
- [ ] `docs/config-sync-plan.md` が実装済みステータスへ更新
- [ ] memory→rules 昇格運用が dotfiles README に明記
- [ ] doctor.ps1（任意）が dotfiles 展開物のパリティも検査
- [ ] Laptop（`C:\Users\sawa3`）で `install.ps1` を流して壊れない（パスが sawa3 配下に解決）

## 8. レビュー方法

- 完了後、戻ってきた差分は本リポジトリで **`/review-diff`** により reviewer 検収する。
- 検収観点:
  1. **秘密・状態の混入ゼロ**（最優先。`.gitignore` と実際の追跡ファイルの両面で確認）
  2. **可搬性**（機体固有絶対パスが配布物に残っていない。`$env:USERPROFILE`/相対か）
  3. **冪等性**（install.ps1 の2回流し・既存設定の非破壊マージ）
  4. **重複回避**（agents/commands/rules を複製していない＝参照方式）
  5. **振る舞い不変**（hooks の意味を変えていない。パス可搬化のみ）
  6. PS5.1 の罠対応（BOM・stderr 例外化）

## 補足: AGENTS.md 整合

本リポジトリに `AGENTS.md` がある場合、テストコマンド・禁止事項（secrets 不混入、機体固有パス禁止）と矛盾しないか実装前に確認すること。矛盾があればこの HANDOFF ではなく AGENTS.md 側の前提を優先し、相違を報告する。
