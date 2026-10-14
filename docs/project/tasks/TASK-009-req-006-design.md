---
status: done      # todo / in-progress / done / paused
updated: 2026-10-15
related: [REQ-006, DES-006]       # 対応する REQ / DES の ID
frozen_tests:     # 凍結したテストファイル（リポジトリ直下からのパス）。凍結時に追記する（TEST-04）
  - tests/test_shapes.py
  - tests/test_cli.py
---
# TASK-009 REQ-006 の設計

> 以下の4セクション（現在のフェーズ〜未解決事項）は上書き更新する。「作業ログ」だけは追記のみ（DOC-11）。

## 現在のフェーズ
> 探索 / 計画 / 実装（Red / Green / Refactor）/ レビュー のどこにいるか。

完了

## 完了したこと

- PLAN-19 に当たる判断はなく、質問は 0 件。
- 点の置き方の試作（scratchpad の cube_proto.py。プロジェクトには入れない）: 回転角 0、幅 80・高さ 24 で、正面のフレームに現れた文字と、1フレームの計算時間（5回計った最短）を比べた。
  - 辺を含む格子（61 × 61 × 6 = 22326 点）: 正面の面を最初に並べると `*` だけだった。最後に並べると `*` と `.` が混ざった。
  - マスの中心（60 × 60 × 6 = 21600 点）: 正面の面を最後に並べても `*` だけだった。一番遠い点の距離は 1.0、計算時間は約 0.026 秒だった。
- DES-006（変更するファイル3つ: src/spin/shapes.py、tests/test_shapes.py、tests/test_cli.py）と、test-items.md の DES-006 の見出し（11 項目）を作成した。
- REQ-006 の受け入れ基準の割り当て（PLAN-13）:
  - 基準 1: DES-006 #1〜#3、#11。
  - 基準 2: DES-006 #1・#6・#10。REQ-001 基準 1〜5 は、DES-001 の全図形の項目で確かめる。
  - 基準 3: DES-006 #7。
  - DES-004 から回された REQ-004 基準 1 の `cube` の部分: DES-006 #2。
  - TASK-002 の未解決事項（既定以外の図形を位置引数で選べることの確認）: DES-006 #2。
- architecture.md と glossary.md は変えない（`cube` は登録済み）。

## 次の一手
> 再開したセッションが最初に行うこと。再開する Skill（引数を含む）と手順の番号、最初に行う1つの具体的な行動を書く（DOC-21）。

なし（完了）

## 未解決事項

- 残した P2（plan-reviewer 確認ラウンド）: DES-006 の `related` に、本文で根拠にしている REQ-001・REQ-002 がない。
- 残した P2（test-reviewer r1）: (1) tests/test_shapes.py・tests/test_cli.py のモジュールの説明に DES-006 がない (2) `AXIS_DIRECTIONS` と `_matching_axis_direction` がファイルの途中にあり、先頭の定数・補助関数と置き方がそろっていない (3) DES-006 #6 の `count <= 30000` は `count == 21600` の後では必ず成り立つ。
- 残した P2（code-reviewer r1）: (1) `_cube_point` が軸の番号をキーにした辞書を2つ作ってからタプルに詰め直していて、対応が読み取りにくい (2) 軸の数 `3` が `range(3)` として2か所に直接書かれている。

## 作業ログ
> 書き方は DOC-12、書くタイミングは DOC-13。新しい記録を下に足す。

- 2026-10-15 計画: DES-006 と test-items.md の DES-006 の見出し（11 項目）を作成。点の置き方を scratchpad で試作して比べた。質問 0 件
- 2026-10-15 レビュー: plan-reviewer ラウンド1: 合格 P0=0 P1=0 P2=4 保留0。P2 4件（k の数値の誤り、基準 3 の根拠にマスの範囲を追加、基準 2 の確かめ方の記述、related）を直した
- 2026-10-15 レビュー: plan-reviewer 確認ラウンド（REV-27）: 合格 P0=0 P1=0 P2=1。P2 は未解決事項に記録
- 2026-10-15 レビュー: ユーザーが DES-006 を承認。DES-006 を final にした。DES が1つのため、この TASK で実装に進む（WF-08）
- 2026-10-15 実装（Red）: shapes.py に cube のスタブを追加（SHAPES は変えない）、tests/test_shapes.py・tests/test_cli.py にテストを追加。新しい 6 件が失敗（アサーション 2、NotImplementedError 3、SystemExit(2) 1 は DES-006 の判断どおり）、既存 83 件と保持 2 件が成功。リント・フォーマット成功
- 2026-10-15 実装（Red）: test-reviewer ラウンド1: 合格 P0=0 P1=0 P2=3 保留0。テストを凍結（コミット de4437f）
- 2026-10-15 実装（Green）: shapes.py に cube を実装し SHAPES に追加。テスト 91 件成功、カバレッジ 99.44%、リント・フォーマット成功。Refactor は不要と判断
- 2026-10-15 レビュー: code-reviewer ラウンド1: 合格 P0=0 P1=0 P2=2 保留0。P2 は未解決事項に記録
- 2026-10-15 完了: ユーザーが DES-006 #10・#11（人間確認）を OK と回答（#10 の秒数の報告はなし。手元の計測では cube 0.029 秒）。TASK を done にした
