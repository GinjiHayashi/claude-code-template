---
status: done
updated: 2026-10-14
related: [REQ-003, DES-004]
frozen_tests:     # 凍結したテストファイル（リポジトリ直下からのパス）。凍結時に追記する（TEST-04）
  - tests/test_cli.py
---
# TASK-009 DES-004 の実装（不正な入力のエラー）

> 以下の4セクション（現在のフェーズ〜未解決事項）は上書き更新する。「作業ログ」だけは追記のみ（DOC-11）。

## 現在のフェーズ
> 探索 / 計画 / 実装（Red / Green / Refactor）/ レビュー のどこにいるか。

完了

## 完了したこと

- DES-004 の実装（cli.py の引数検証、test_cli.py のテスト追加）。全1703件成功
- test-reviewer・code-reviewer で合格
- 人間確認（エラーメッセージだけでどの値をどう直せばよいか分かる）をユーザーが確認

## 次の一手
> 再開したセッションが最初に行うこと。1つの具体的な行動で書く。

なし（全要件の実装が完了）

## 未解決事項

（なし）

## 作業ログ
> 書き方は DOC-12、書くタイミングは DOC-13。新しい記録を下に足す。

- 2026-10-14 計画: DES-004 の承認を受けて TASK を作成し、実装を開始
- 2026-10-14 実装（Red）: cli.py に検証用の内部関数 _parse_request のスタブ（NotImplementedError）を追加し main の先頭で呼ぶ形にした。test_cli.py に DES-004 のテストを追加。Red 確認: test_cli.py の54件すべて失敗（NotImplementedError 52件、サブプロセス2件はアサーション失敗）。既存の DES-002・003 の CLI テストも Green まで一時的に失敗する。test_calc.py の1649件は成功
- 2026-10-14 レビュー（テスト）: test-reviewer ラウンド1 合格（P0=0 P1=0 P2=2、保留0）。P2 2件を修正（項目19で標準出力が空の確認、起動口テストで Traceback がなく『エラー: 』で始まる確認）。Red 再確認: test_cli.py の54件すべて失敗（NotImplementedError 52件、アサーション失敗2件）
- 2026-10-14 レビュー（テスト）: test-reviewer ラウンド2 合格（P0=0 P1=0 P2=2、保留0）。P2（エラー形式の厳密な確認、補助関数の重複）は DES のテスト項目外・書き方の提案のため見送り。既存テストの削除行0件を確認。tests/test_cli.py を凍結（コミット 1020774）
- 2026-10-14 実装（Green/Refactor）: cli.py に引数検証を実装（_Parser の error 上書き、parse_known_intermixed_args、allow_abbrev=False、usage と metavar を定数から組み立て）。ruff の FLY002 は f-string に書き換えて解消。全1703件成功、cli.py・calc.py の Cover 100%。Refactor の追加変更なし
- 2026-10-14 レビュー（コード）: code-reviewer ラウンド1 合格（P0=0 P1=0 P2=2、保留0）。P2#1（方式の一覧の重複）を修正し _METHODS に集約。P2#2（ラベル文字列が calc.py と cli.py の2か所）は calc.py が DES-004 の配置外のため見送り。全1703件成功・ruff 成功を再確認。人間確認をユーザーに依頼
- 2026-10-14 レビュー（人間確認）: ユーザーがエラー表示を確認し問題なし。TASK-009 を完了
