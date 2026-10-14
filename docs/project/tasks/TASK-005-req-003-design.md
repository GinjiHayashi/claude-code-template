---
status: done      # todo / in-progress / done / paused
updated: 2026-10-15
related: [REQ-003, DES-003]       # 対応する REQ / DES の ID
frozen_tests:     # 凍結したテストファイル（リポジトリ直下からのパス）。凍結時に追記する（TEST-04）
---
# TASK-005 REQ-003 の設計

> 以下の4セクション（現在のフェーズ〜未解決事項）は上書き更新する。「作業ログ」だけは追記のみ（DOC-11）。

## 現在のフェーズ
> 探索 / 計画 / 実装（Red / Green / Refactor）/ レビュー のどこにいるか。

完了

## 完了したこと

- 質問の一覧（全1問）:
  - 1/1 カバレッジ 90% の確かめ方（REQ-003 と TEST-20 の衝突）: A（pyproject.toml の coverage の設定に fail_under = 90 を置き自動で判定。TEST-20 の例外として DES に記録）
- 既存の事実: 今の TOTAL は 99%。pytest-cov が coverage の設定の fail_under を読み、下回ると終了コード 1 になることを確認。
- DES-003（pyproject.toml の設定だけを変更）と test-items.md の DES-003 の見出しを作成。REQ-003 の基準 1 は DES-003 #2・#3 で検証する（PLAN-13）。

## 次の一手
> 再開したセッションが最初に行うこと。再開する Skill（引数を含む）と手順の番号、最初に行う1つの具体的な行動を書く（DOC-21）。

なし（次の作業は /plan-spec REQ-004 で設計）

## 未解決事項

- 残した P2（plan-reviewer r1）:
  1. 「90% 未満なら終了コード 1」の側を確かめるテスト項目がない（`--cov-fail-under=100` を付けて失敗を確かめる人間確認を足すとよい）。
  2. DES-003 の「採用しなかった案」が処理方針と判断の表の両方にある。
  3. architecture.md のディレクトリ構成の pyproject.toml の注記に coverage の設定が入っていない（次に architecture.md を改訂するときに直す）。
  4. TEST-20 の例外が DES-003 にしか書かれていない（tech.md の「テストツール」に参照を足すことを検討）。

## 作業ログ
> 書き方は DOC-12、書くタイミングは DOC-13。新しい記録を下に足す。

- 2026-10-15 計画: 質問 1 件（カバレッジの確かめ方: A 自動で下限）。DES-003 と test-items.md の DES-003 の見出し（3 項目）を作成
- 2026-10-15 レビュー: plan-reviewer ラウンド1: 合格 P0=0 P1=0 P2=4 保留0。P2 は未解決事項に記録
- 2026-10-15 レビュー: ユーザーが DES-003 を承認し final にした。DES が1つのため、この TASK で実装に進む（WF-08）
- 2026-10-15 実装: pyproject.toml に [tool.coverage.report] fail_under = 90 を追加。テスト（全件）33 件成功、Required test coverage of 90.0% reached（98.86%）、終了コード 0。リント・フォーマット成功。code-reviewer ラウンド1: 合格 P0=0 P1=0 P2=1 保留0（未解決事項 3 と同じ内容）
- 2026-10-15 完了: 人間確認 DES-003 #3: ユーザーの環境で reached（98.86%）・終了コード 0 を確認。DES-003 の実装を完了
