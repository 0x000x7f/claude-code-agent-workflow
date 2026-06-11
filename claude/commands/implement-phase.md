---
description: docs/refactor-plan.md の指定 Phase を実装する。PM として複雑度を判断し implementer / implementer-heavy / 本体続投をルーティングし、完了後 reviewer で検収する
argument-hint: <Phase 番号>
---

`docs/refactor-plan.md` を読み、Phase $ARGUMENTS のみを実装してください。計画ファイルがない場合は、先に `/analyze-codebase` の実行が必要と報告して止まってください。

引数（Phase 番号）が空の場合は、実装に入らず、対象の Phase 番号をユーザーに確認してください。また、指定された Phase が `docs/refactor-plan.md` に実在することを確認し、見つからない場合は計画に存在する Phase 一覧を示して再指定を求めてください。

## PM ルーティング（必須）

実装に入る前に、この Phase の複雑度を判断して担当を選び、**判断根拠を1行で報告**する:

- 単純・定型・大量の編集（lint、型エラー、リネーム、定型差分） → **implementer**（Sonnet 4.6）サブエージェント
- 複数ファイル横断・中複雑度・軽い設計判断を含む → **implementer-heavy**（Opus 4.8）サブエージェント
- アーキテクチャ変更・重い設計判断を含む → **本体続投**（サブエージェントに委任しない）

## 実装時の制約（担当へ必ず伝える）

- 振る舞いを変えない（Phase の目的が振る舞い変更そのものである場合を除く）
- 変更ファイルを最小限にし、1つの PR としてレビュー可能な粒度にする
- 既存テストがあれば実行する。なければ最低限の確認手順を示す

## 完了後（必須）

1. reviewer サブエージェントに差分レビューを依頼し、判定（approve / request changes / comment）を得る
2. request changes の場合は指摘を修正して再検収する
3. 最後にまとめて報告: 変更ファイル / 変更理由 / 振る舞いが変わっていない根拠 / 実行したテスト / reviewer 判定 / 残課題
