# 使い方

## インストール

1. `claude/` 配下を `~/.claude/` にコピー:

   ```powershell
   Copy-Item -Recurse -Force .\claude\agents\*   "$env:USERPROFILE\.claude\agents\"
   Copy-Item -Recurse -Force .\claude\commands\* "$env:USERPROFILE\.claude\commands\"
   Copy-Item -Recurse -Force .\claude\rules\*    "$env:USERPROFILE\.claude\rules\"
   ```

2. グローバル `~/.claude/CLAUDE.md` の末尾に2行追記:

   ```markdown
   ## Agent Workflow — PMルーティングとクロスツール分業
   Global workflow rules: @rules/agent-workflow.md
   ```

3. 新しいセッションで `/agents` を実行し、`implementer` / `implementer-heavy` / `reviewer` が
   表示されることを確認する。

## 基本フロー（リファクタリング）

```text
1. /analyze-codebase
   → コードを編集せず調査し、docs/refactor-plan.md に Phase 分け計画を保存

2. 計画をレビュー（人間）
   → Phase の粒度・順序・ロールバック方針を確認

3. /implement-phase 1
   → PM が複雑度を判断して担当を選択（判断根拠を1行報告）
   → 実装 → reviewer が検収（approve / request changes / comment）

4. Phase を1つずつ進める
```

Phase が大きすぎると感じたら、実装前にこう指示する:

```text
Phase 1 を実装する前に、変更範囲を1ファイル以内・挙動変更なし・
即時ロールバック可能な最小サブタスクに縮小してください。
```

## クロスツール分業（Codex / Cursor）

usage limit が近いときや、長時間の定型実装を外部に出したいとき:

```text
1. /handoff <topic>
   → docs/handoff/HANDOFF-<topic>.md に自己完結の実装指示書を生成

2. その文書を Codex / Cursor に渡して実装させる

3. 戻ってきた差分を /review-diff で検収
   → ハンドオフ文書の完了条件・禁止事項に照らして判定される
```

ハンドオフ文書には目的・調査結果・設計・対象ファイル・制約・テストコマンド・完了条件・
レビュー方法が含まれ、このリポジトリや会話の文脈を知らない実装者でも作業できる。

## 日常運用ルール

```text
短い質問・小修正:        メイン会話で処理。サブエージェントを使わない
大量読解・調査:          Explore / analyze-codebase
単純大量編集:            implementer（Sonnet）
複数ファイル横断:        implementer-heavy（Opus）
設計判断が重い変更:      メイン会話が続投
usage limit が近い:      /handoff で外部ツールへ
外部ツールの戻り差分:    /review-diff で必ず検収
```

## カスタマイズ

- **コスト優先にする**: `claude/agents/reviewer.md` に `model: claude-sonnet-4-6` を1行追加
- **model ID がエラーになる環境**: 各 agent の `model:` を alias（`sonnet` / `opus`）に変更
- **reviewer を厳格にする**: `tools:` から `Bash` を外し、テスト実行はメイン会話側に移す
