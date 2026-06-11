# Agent Workflow — PM ルーティングとクロスツール分業

メイン会話（Fable 5）は PM / 設計役。実装・調査・検収は適切な担当へルーティングする。

## PM ルーティング表

| 作業 | 担当 |
|---|---|
| 大量のファイル読解・コードベース調査 | Explore（組み込みサブエージェント） |
| 実装計画・設計 | プランモード or Plan（組み込み） |
| 単純・定型・大量の編集（lint、型エラー、リネーム） | implementer（Sonnet 4.6） |
| 複数ファイル横断・中複雑度の実装 | implementer-heavy（Opus 4.8） |
| 設計判断が重い実装・アーキテクチャ変更 | Fable 5 本体続投 |
| usage limit が近い / 長時間の定型実装 | `/handoff` で Codex/Cursor へ切り出し |
| 差分レビュー・他ツール実装の検収 | reviewer（検収必須の範囲は下記参照） |

## 基本運用

> 普段は Fable 本体で進める。
> 読む量が多いときだけ Explore / Plan。
> 書く量が多く単純なら Sonnet（implementer）。
> 複数ファイル横断なら Opus（implementer-heavy）。
> 設計判断が重いなら Fable 本体続投。
> usage limit が近いなら /handoff で Codex/Cursor へ切る。
> 戻り差分は必ず reviewer で検収。

## サブエージェントの使いどころ（重要）

サブエージェント分業は万能戦略ではなく、**メイン会話のコンテキスト汚染対策**。

- 使う: 大量のファイル読解・ログ解析・検索結果・長い定型実装など、メイン文脈を汚す作業
- 使わない: 短いタスク、小修正、単発質問。コールドスタートのコスト・遅延・再説明の負担が上回る

## 検収必須の範囲

reviewer 検収が**必須**なのは次の2つだけ: (1) Codex/Cursor 等の他ツールから戻ってきた差分、(2) `/implement-phase` の成果。それ以外の自前の小さな差分のレビューは任意（「短いタスクにサブエージェントを使わない」原則を優先する）。

## ファイルベース文脈共有の原則

調査結果・設計・実装指示は会話内だけに残さず、プロジェクト内 `docs/` 配下の Markdown に固定する。Claude 内部メモリに依存させないことで、Codex/Cursor 等の他ツール・別セッションと文脈を共有できる。

- `docs/refactor-plan.md` — `/analyze-codebase` の成果物。Phase 分けされたリファクタ計画
- `docs/handoff/HANDOFF-<topic>.md` — `/handoff` の成果物。他ツールへ渡す自己完結実装指示書

## クロスツール分業（Codex / Cursor）

- 渡すとき: `/handoff <topic>` で自己完結文書を生成。このセッションを知らない実装者が読んで作業できることが品質基準
- 受けるとき: 戻ってきた差分は**必ず `/review-diff` で reviewer 検収**してから取り込む
- AGENTS.md との整合: Codex は作業前に AGENTS.md を読む。ツール間で共有したい前提（テストコマンド、禁止事項、コーディング規約）はプロジェクトの AGENTS.md に書き、CLAUDE.md と矛盾させない

## 注記

- lean-ctx の CEP ルール（ONE LINE・Never narrate 等）はメイン会話のツール出力様式に適用されるもの。サブエージェントの報告形式は各エージェント定義（agents/*.md）の指定に従う
- `~/.claude/commands/` は後方互換の legacy 形式。将来テンプレート・スクリプト同梱が必要になったら `~/.claude/skills/<name>/SKILL.md` への移行を検討
- reviewer はメインモデル継承（高品質・高コスト）。高頻度運用になったら `~/.claude/agents/reviewer.md` に `model: claude-sonnet-4-6` を1行追加してコストを下げる
