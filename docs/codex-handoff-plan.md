# Roadmap: codex-handoff を本リポジトリに畳み込み、複数機体へ展開する（計画）

> このドキュメントは計画メモ。codex-handoff 自体は 2026-07-04 に Desktop 機で構築・E2E 検証済みだが、
> **本リポジトリの配布物には未収録**であり、他機体（laptop 等）へは未展開。その解消計画。

## codex-handoff とは（現状の要約）

Claude Code (Opus/Fable) の usage limit に対し、**人手なしで Codex CLI に作業を引き継ぎ、リセット後に検収する**自動操縦。
「常に Codex を使う」ではなく「**Anthropic のリミットが近づいたら退避する**」リミット生存機構。

- しきい値: 使用量 **70% で警告注入 / 85% で自動ハンドオフ / rate_limit 到達でリアクティブ発火**
- リセット時刻に Windows タスクで中断セッションを `claude --resume` 自動再開 + 検収キュー処理
- 正本ドキュメント: 導入機体の `~/.claude/codex-handoff/README.md`
- 対象は **git リポジトリのみ**（検収 `/review-diff` の前提）。Codex は commit せず、差分は working tree に残す

## 確認済みの構成（導入機体 = Desktop, ユーザー名 `User`）

実体は `~/.claude/` 配下に散在:

| 種別 | パス | 役割 |
|---|---|---|
| スクリプト | `~/.claude/scripts/codex-handoff/{guard,launch,resume,lib}.mjs` | hook 本体・codex 起動・再開・共通処理（Node ESM） |
| 設定 | `~/.claude/codex-handoff/config.json` | enabled / warnPct / criticalPct / codex.windowsSandbox 等 |
| 実行時状態 | `~/.claude/codex-handoff/{state.json,usage-cache.json,logs/}` | **機体ローカル。共有・コピー対象外** |
| 手動コマンド | `~/.claude/commands/codex-handoff.md` | `/codex-handoff <topic>` |
| hook 登録 | `~/.claude/settings.json` の Stop / StopFailure / UserPromptSubmit / SessionStart | guard.mjs を4フックに配線 |
| 動的タスク | Windows タスク `codex-handoff-resume` | StopFailure 時に自己登録・発火後自己削除 |

`config.json` の要点:
- `codex.windowsSandbox: "unelevated"` は**必須**（ネイティブ Windows では未設定だと Codex が read-only に降格する実測あり）
- `tokenLimit: "auto"`（観測リミット中央値で自己補正するヒューリスティック。Anthropic の実限度は不透明）
- `resume.permissionArg: "--dangerously-skip-permissions"`（headless 再開は権限プロンプトに応答できないため）

## 課題（なぜ今のままでは laptop に展開できないか）

1. **配布リポジトリに入っていない。** 本リポジトリの `claude/` が配っているのは `agents/` `commands/(analyze-codebase, handoff, implement-phase, review-diff)` `rules/agent-workflow.md` のみ。codex-handoff の scripts / config / codex-handoff.md / settings.json hook はどれも未収録。→ 他機体は「手動コピー + 手直し」しか手段がない。
2. **パスのハードコード。** `settings.json` の4 hook は `node "C:/Users/User/.claude/scripts/codex-handoff/guard.mjs" ...` を**機能的に**直書き。別ユーザー名の機体（例: laptop は `sawa3`）では `C:/Users/sawa3/...` に書き換えが必要。加えて `guard.mjs` の一部**表示メッセージ**にも `C:/Users/User/...` がハードコードされており（状態解決自体は `os.homedir()` で可搬）、他機体で誤った案内文を出す。

## 方針

**codex-handoff を本リポジトリに畳み込み、パスを可搬化してから、既存の Copy-Item インストール経路で配布する。**
そうすれば各機体は「`git pull` → `install` → `codex login`」で揃い、以後は `git pull` で同期される（手動コピー＆username 手直しのドリフトが消える）。

### やること（実装フェーズ）
1. **repo 化**: `claude/scripts/codex-handoff/*.mjs`・`claude/codex-handoff/config.json`（config のみ。state/logs/usage-cache は除外）・`claude/commands/codex-handoff.md` を追加。`.gitignore` で実行時状態を除外。
2. **パス可搬化**: `guard.mjs` の表示メッセージ内 `C:/Users/User/...` を `os.homedir()` 由来に置換。`settings.json` の hook は機体ごとに username が異なるため、インストーラ（PowerShell）で `$env:USERPROFILE` を埋め込んで生成する方式にする（README のインストール節に手順追加）。
3. **README 追記**: インストール節に「codex-handoff を使う場合」の追加手順（settings.json への hook マージ、`config.json` 配置、前提ツール）を書く。

### 各機体の追加前提（laptop で必要なもの）
- **Codex CLI 導入 + `codex login`**（`~/.codex/auth.json`）。⚠ Codex のクォータは**アカウント単位**。同一 ChatGPT/OpenAI アカウントでログインすると複数機体で**同じ Codex 枠を食い合う**（退避先の余力は別問題として残る）。
- **Node.js**（`.mjs` 実行用）
- **Claude Code ≥ 2.1.78**（StopFailure hook 対応。参考: Desktop は 2.1.175 で動作確認済み）
- **コピーしないもの**: `state.json` / `usage-cache.json` / `logs/`（機体ローカルの実行時状態。共有すると観測リミットや pending が混線する）

## 設計上の論点（未解決）

- **settings.json の hook をどう可搬に配るか。** 案A: インストーラで `$env:USERPROFILE` を展開して生成（機体非依存だが settings.json への安全なマージ処理が要る）。案B: hook 起動を絶対パスでなく相対解決できるラッパー経由にする（Claude Code の hook 実行 cwd の仕様確認が必要）。
- **Codex クォータの相互監視。** Claude 側が枯れて Codex に退避しても、Codex 側も同アカウントで枯れていれば退避が無意味。両者の残量をハンドオフ判断に織り込むか。
- **多機体での二重発火。** 別機体で同時にリミットに達した場合の Windows タスク名衝突（現状 `-Force` 上書きで同一機体内は集約されるが、機体間は独立）。

## 関連

- 手動運搬の自動化という上位テーマは `docs/codex-mcp-plan.md`（Codex CLI の MCP サーバー化）と地続き。
- 導入機体の正本: `~/.claude/codex-handoff/README.md`（全体フロー図・config 詳細・実測に基づく注意・検証履歴）。
