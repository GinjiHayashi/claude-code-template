---
status: in-progress
updated: 2026-10-14
related: [REQ-002, DES-003]
frozen_tests:     # 凍結したテストファイル（リポジトリ直下からのパス）。凍結時に追記する（TEST-04）
  - tests/test_calc.py
  - tests/test_cli.py
---
# TASK-007 DES-003 の実装（多めに集める）

> 以下の4セクション（現在のフェーズ〜未解決事項）は上書き更新する。「作業ログ」だけは追記のみ（DOC-11）。

## 現在のフェーズ
> 探索 / 計画 / 実装（Red / Green / Refactor）/ レビュー のどこにいるか。

レビュー（人間確認待ち）

## 完了したこと

- DES-003 の実装（calc.py、cli.py、テスト追加）。全1665件成功
- test-reviewer・code-reviewer で合格

## 次の一手
> 再開したセッションが最初に行うこと。1つの具体的な行動で書く。

ユーザーに DES-003 の人間確認の結果を聞き、問題なければ TASK を done にする

## 未解決事項

（なし）

## 作業ログ
> 書き方は DOC-12、書くタイミングは DOC-13。新しい記録を下に足す。

- 2026-10-14 計画: DES-003 の承認を受けて TASK を作成し、実装を開始
- 2026-10-14 実装（Red）: calc.py に CollectExtraSplit と split_collect_extra のスタブ、cli.py に collect-extra の選択肢と未実装エラーを追加。test_calc.py・test_cli.py に DES-003 のテストを追加。Red 確認: 新規831件すべて NotImplementedError で失敗（計算824件、CLI 7件）。既存834件は成功
- 2026-10-14 レビュー（テスト）: test-reviewer ラウンド1 合格（P0=0 P1=0 P2=2、保留0）。P2 2件（期待値のキーワード引数化、テスト名の項目番号）を修正。Red 再確認: 新規831件すべて NotImplementedError で失敗、既存834件成功
- 2026-10-14 レビュー（テスト）: test-reviewer ラウンド2 合格（P0=0 P1=0 P2=0）。tests/test_calc.py・tests/test_cli.py を凍結（コミット 2aabbff）
- 2026-10-14 実装（Green/Refactor）: split_collect_extra を実装し、入力検証を _validate_inputs にまとめて2関数で共用。cli.py を方式ごとの出力行を返す関数に整理。全1665件成功、calc.py の Cover 100%、ruff format・check 成功
- 2026-10-14 レビュー（コード）: code-reviewer ラウンド1 合格（P0=0 P1=0 P2=1、保留0）。P2（出力行の組み立て方の不揃い）を修正し、_per_person_line を廃止して3種類の行を _result_lines 内でそろえた。全1665件成功、ruff 成功を再確認。人間確認をユーザーに依頼
