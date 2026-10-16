# remote-change-log — 別の PC を遠隔で変えたら、その PC に変更記録を残す

SSH（Tailscale 経由）などで別の PC を変更すると、変更された側の Claude やユーザーは何が起きたかを知る手段がない。
会話の記録は変更した側の PC にしか残らないため、**変更された PC 自身**に記録を残す。

## 対象

- SSH、Desktop Commander など、遠隔で別の PC に対して行った変更のうち、あとに残るもの:
  - ファイルの作成・上書き・削除・移動（`~/.claude` の設定、ルール、スクリプトなど）
  - 設定の変更（`settings.json`、`claude mcp add/remove`、レジストリ、環境変数）
  - タスクスケジューラ、サービス、インストール・アンインストール
  - バックアップファイルの作成
- 読むだけの操作（状態確認、一覧表示、`git status` など）は記録しない。

## 書き方

- 記録先: 変更された PC の `~/.claude/change-log.md`（無ければ作る）。新しいものを末尾に追記し、既存の行は書き換えない。
- 変更と同じ遠隔セッションの中で追記する。変更が失敗した場合も、途中まで変わったものがあれば記録する。
- 1件1行で、次の形にする:

```
- 2026-10-16 16:53 JST | from: <変更元の PC 名> | <何をしたか> | backup: <バックアップのパス、無ければ なし> | undo: <元に戻すコマンドや手順>
```

- 「何をしたか」はパスや対象名を含め、あとから見て分かる具体さで書く（例:「settings.json の UserPromptSubmit に now-context.mjs の hook を追加」）。
- undo は、そのまま実行できるコマンドを優先する。戻せない変更なら「戻せない」と書く。
- パスワード、トークン、API キーなどの秘密は書かない。

追記の例（遠隔で実行するスクリプトの最後に入れる）:

```powershell
$log = Join-Path $env:USERPROFILE '.claude\change-log.md'
$ts  = (Get-Date).ToString('yyyy-MM-dd HH:mm') + ' JST'
Add-Content -Path $log -Encoding utf8 -Value "- $ts | from: <変更元の PC 名> | <何をしたか> | backup: <パス> | undo: <コマンド>"
```

## 読む側

- 自分の PC の設定やツールの不具合を調べるとき、または「最近何か変えた？」と聞かれたときは、先に `~/.claude/change-log.md` の末尾を確認する。
- ユーザーへの報告では、遠隔で何を変えたかに加えて、change-log に記録したことも伝える。
