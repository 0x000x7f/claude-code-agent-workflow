---
description: reviewer サブエージェントで差分を検収する。引数なしなら現在の working tree、引数ありなら指定ブランチ・ファイル・範囲をレビュー
argument-hint: [ブランチ名・ファイル・コミット範囲（省略可）]
---

reviewer サブエージェントを使って差分レビューを実行してください。

対象: $ARGUMENTS
（指定がなければ現在の working tree の未コミット差分。指定があればそのブランチ・コミット範囲・ファイルの差分）

## reviewer へ渡すもの

- レビュー対象の特定方法（git diff の範囲など）
- 関連する計画・ハンドオフ文書のパス（`docs/refactor-plan.md`、`docs/handoff/HANDOFF-*.md` があれば）— 完了条件・禁止事項に照らして検収させる

## 報告（reviewer の結果を要約して出す）

1. 判定: approve / request changes / comment
2. 重大な問題
3. 軽微な問題
4. 追加テスト案
5. 次へ進んでよいか

Codex/Cursor など他ツールで実装された差分の検収にもこのコマンドを使う。
