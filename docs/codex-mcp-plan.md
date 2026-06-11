# Roadmap: Codex CLI 連携の次フェーズ（計画）

> このドキュメントは次フェーズの計画メモであり、未実装。

## 現状

- Claude → Codex / Cursor への作業引き渡しは `/handoff` が生成する Markdown 文書で行う（手動運搬）
- 戻り差分の検収は `/review-diff`（reviewer エージェント）で行う

## 次フェーズ案: Codex CLI の MCP サーバー化

ハンドオフの「手動運搬」部分を自動化する。

1. **Codex CLI の実運用検証** — ハンドオフ文書を実際に Codex CLI に渡し、AGENTS.md の解釈・
   完了条件の遵守・差分の品質を確認する
2. **MCP サーバー化** — Codex CLI を MCP ツールとして Claude Code に接続し、
   `/handoff` 生成 → Codex 実行 → 差分取得 → `/review-diff` 検収までを1フローにする
3. **自動クロスレビューループ** — reviewer の request changes を Codex へ自動で差し戻す

## 設計上の論点（未解決）

- Codex 実行の権限境界（どのディレクトリ・どのコマンドを許可するか）
- 失敗時のフォールバック（タイムアウト・部分適用された差分の扱い）
- usage limit の相互監視（Claude 側と Codex 側のどちらが逼迫しているかの判断材料）
