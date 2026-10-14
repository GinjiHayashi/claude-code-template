---
status: done
updated: 2026-10-14
related: [REQ-001, REQ-004, DES-001]
frozen_tests:     # 凍結したテストファイル（リポジトリ直下からのパス）。凍結時に追記する（TEST-04）
  - tests/test_calc.py
---
# TASK-004 DES-001 の実装（幹事負担の計算とプロジェクトの土台）

> 以下の4セクション（現在のフェーズ〜未解決事項）は上書き更新する。「作業ログ」だけは追記のみ（DOC-11）。

## 現在のフェーズ
> 探索 / 計画 / 実装（Red / Green / Refactor）/ レビュー のどこにいるか。

完了

## 完了したこと

- DES-001 の実装（pyproject.toml、パッケージ、calc.py、tests/test_calc.py）。825件成功、calc.py の Cover 100%（REQ-004）
- test-reviewer・code-reviewer で合格

## 次の一手
> 再開したセッションが最初に行うこと。1つの具体的な行動で書く。

`/implement-tdd DES-002` を実行する（TASK-005）

## 未解決事項

（なし）

## 作業ログ
> 書き方は DOC-12、書くタイミングは DOC-13。新しい記録を下に足す。

- 2026-10-14 計画: DES-001 の承認を受けて TASK を作成
- 2026-10-14 実装（Red）: pyproject.toml・パッケージ・calc.py のスタブ・tests/test_calc.py を作成し uv sync。Red 確認: 825件中825件が NotImplementedError で失敗（import・構文エラーなし）
- 2026-10-14 レビュー（テスト）: test-reviewer ラウンド1 合格（P0=0 P1=0 P2=3、保留0）。P2#1（判定順序テストで「人数」を含まないことも確認）を修正。P2#2・#3 は DES の機械検証項目外のため見送り。修正後の Red 再確認: 825件中825件が NotImplementedError で失敗
- 2026-10-14 レビュー（テスト）: test-reviewer ラウンド2 合格（P0=0 P1=0 P2=3、保留0）。P2 はいずれも DES の機械検証項目外のため見送り。tests/test_calc.py を凍結（コミット 8db5f6a）
- 2026-10-14 実装（Green/Refactor）: calc.py を実装。825件成功、calc.py の Cover 100%、ruff format・check 成功。Refactor でラベル定数を非公開名に変更し、全テスト成功を再確認
- 2026-10-14 レビュー（コード）: code-reviewer ラウンド1 合格（P0=0 P1=0 P2=0、保留0）。人間確認の項目は DES-001 で該当なし。TASK-004 を完了
