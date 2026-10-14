---
status: in-progress
updated: 2026-10-14
related: [REQ-001, DES-002]
frozen_tests:     # 凍結したテストファイル（リポジトリ直下からのパス）。凍結時に追記する（TEST-04）
  - tests/test_cli.py
---
# TASK-005 DES-002 の実装（幹事負担のコマンドライン）

> 以下の4セクション（現在のフェーズ〜未解決事項）は上書き更新する。「作業ログ」だけは追記のみ（DOC-11）。

## 現在のフェーズ
> 探索 / 計画 / 実装（Red / Green / Refactor）/ レビュー のどこにいるか。

レビュー（人間確認待ち）

## 完了したこと

- DES-002 の実装（cli.py、__main__.py、.gitignore、tests/test_cli.py）。全834件成功
- test-reviewer・code-reviewer で合格

## 次の一手
> 再開したセッションが最初に行うこと。1つの具体的な行動で書く。

ユーザーに DES-002 の人間確認の結果を聞き、問題なければ TASK を done にする

## 未解決事項

（なし）

## 作業ログ
> 書き方は DOC-12、書くタイミングは DOC-13。新しい記録を下に足す。

- 2026-10-14 計画: DES-002 の承認を受けて TASK を作成
- 2026-10-14 実装（Red）: cli.py・__main__.py のスタブと tests/test_cli.py を作成。Red 確認: DES-002 の9件すべて失敗（NotImplementedError 8件、起動口テストのアサーション失敗 1件）。既存 825件は成功
- 2026-10-14 レビュー（テスト）: test-reviewer ラウンド1 合格（P0=0 P1=0 P2=1、保留0）。P2（subprocess のタイムアウト）を修正し timeout=30 を追加。Red 再確認: 9件すべて失敗（NotImplementedError 8件、アサーション失敗 1件）
- 2026-10-14 レビュー（テスト）: test-reviewer ラウンド2 合格（P0=0 P1=0 P2=2、保留0）。P2（parametrize の ids、サブプロセスの前提の明記）は検証内容に影響しないため見送り。tests/test_cli.py を凍結（コミット 77567ec）
- 2026-10-14 実装（Green/Refactor）: cli.py・__main__.py・.gitignore を実装。834件成功、ruff format・check 成功。Refactor で argv の None 処理を argparse に任せて簡略化し、方式の定数を非公開名に変更。全テスト成功を再確認
- 2026-10-14 レビュー（コード）: code-reviewer ラウンド1 合格（P0=0 P1=0 P2=1、保留0）。P2（main が args.method を参照しない）は REQ-002 の実装で方式の分岐を入れる際に解消するため見送り。人間確認をユーザーに依頼
