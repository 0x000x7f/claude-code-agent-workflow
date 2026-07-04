# Roadmap: `~/.claude` 設定を機体間で同期する（別 dotfiles repo・計画）

> このドキュメントは計画メモであり、未実装。
> 決定事項: **`~/.claude` の可搬設定は専用 dotfiles repo に集約**する。本リポジトリ
> (`claude-code-agent-workflow`) はその中の1コンポーネントとして **co-evolve** し、両者の
> README に相互の関係を明記する。

## 背景と問題

Claude Code の設定（`~/.claude/`）を Desktop / laptop など複数機体で「同じ」に保ちたい。
ところが `~/.claude/` の中身は性質がバラバラで、**まとめて1つの方法では同期できない**:

- 一部はコピーで揃う設定、一部は機体ローカルの実行時状態、一部はファイルでなく外部インストールが要る。
- さらに「共有したい設定ファイル」の中に「機体固有の絶対パス」が同居している（例: `settings.json`
  の hook コマンドが `C:/Users/<name>/.claude/...` を直書き）ため、丸ごとコピーでは壊れる。

現状の同期は `claude-code-agent-workflow` リポジトリが `claude/agents,commands,rules` を各機体へ
`Copy-Item` で展開する形だけが存在し、skills / hooks / codex-handoff / MCP / plugins は未カバー。

## 対象の3分類（棚卸し結果, `~/.claude` 実物ベース）

| 分類 | 実物 | 扱い |
|---|---|---|
| **A. 同一化したい設定（版管理して配布）** | `CLAUDE.md`, `agents/`, `commands/`, `rules/`, 自作 `skills/`, `hooks/`, `codex-handoff`(scripts+config), `settings.json` の可搬部分 | dotfiles repo に「設定として」置き、install スクリプトで各機体へ展開 |
| **B. 機体ローカル状態・秘密（共有しない）** | `projects/`, `sessions/`, `history.jsonl`, `cache/`, `backups/`, `shell-snapshots/`, `session-env/`, `plans/`, `*-cache.json`, `policy-limits.json`, `remote-settings.json`／MCP 認証・`~/.codex/auth.json`・PAT | `.gitignore` で除外。**絶対にコミットしない**（状態混線・秘密漏洩） |
| **C. 外部インストールが要るもの（ファイル共有では揃わない）** | MCP サーバー群, `plugins/`(marketplace), Codex CLI, `skills/lean-ctx`(npm 自動), Node.js | 「導入手順（bootstrap/マニフェスト）」で揃える。設定に定義を書いても実体が無ければ動かない |

## 決定した構成: 別 dotfiles repo + co-evolve

### repo 境界
- **dotfiles repo（新設・アンブレラ）**: `~/.claude` 可搬設定の全体と **bootstrap インストーラ**を持つ。A の大半 + C の導入手順。
- **`claude-code-agent-workflow`（既存・コンポーネント）**: マルチエージェント PM ルーティング／handoff／review の
  `agents,commands,rules` の **source of truth のまま**。dotfiles はこれを重複保持せず、bootstrap から
  **呼び込む**（下記カップリング）。

### カップリング方式（論点・推奨あり）
- **推奨: 参照方式（疎結合）** — dotfiles の bootstrap が `claude-code-agent-workflow` を clone/pull して
  その install を実行する。2 repo は独立に版管理でき、README を相互リンクするだけで関係が保てる。submodule の
  取り回しコストを避けられる。
- 代替: git submodule / subtree で dotfiles 内にピン留め。バージョン固定は強いが取り回しが重い。

### README 相互参照（この決定の必須要件）
- `claude-code-agent-workflow` README: 「本 repo は `~/.claude` 全体を管理する dotfiles repo の1コンポーネント。
  agents/commands/rules の source of truth はここ」を明記（本コミットで Roadmap にリンク追加）。
- dotfiles README（新設時）: 「アンブレラ。agent-workflow を参照コンポーネントとして取り込む」を明記。

## bootstrap 方針

各機体で「1発で揃う」ことを目標にする:

```
git clone <dotfiles repo> ; cd dotfiles
pwsh ./install.ps1
  ├ A: claude/* を ~/.claude/ へ Copy-Item（agent-workflow の install も内部で呼ぶ）
  ├ settings.json: 機体固有値を $env:USERPROFILE で展開して生成/マージ（丸ごと上書きしない）
  ├ B: 何もしない（.gitignore 済み・機体ローカルのまま）
  └ C: マニフェストに沿って導入 → Codex CLI / Node / MCP サーバー / plugins
        + 認証は各機体で手動（codex login 等）。定義は配る・秘密は配らない
```

## 未解決の論点

- **dotfiles repo 名**（候補: `claude-dotfiles` / `claude-config` / `dotfiles`）。
- **`settings.json` の安全なマージ**: 既存の hook/permissions を壊さず、機体固有パスだけ差し替える方式。
  丸ごと上書きは事故のもと（現行 settings.json は hook 定義と絶対パスが同居）。
- **MCP 定義の可搬化**: server 起動コマンドが機体ローカルのバイナリ/パスに依存する場合の抽象化。認証は必ず機体側。
- **codex-handoff の取り込み**: `docs/codex-handoff-plan.md` の repo 化と本計画のスコープは重なる。
  codex-handoff は dotfiles の A/C にそのまま吸収する（別々に repo 化しない）。
- **公開範囲**: dotfiles は private 前提（機体名・パス・構成が漏れるため）。

## 関連

- `docs/codex-handoff-plan.md` — codex-handoff（リミット自律ハンドオフ）の repo 化計画。本計画に吸収される下位テーマ。
- `docs/codex-mcp-plan.md` — 手動運搬の自動化（Codex MCP 化）。
