---
status: done      # todo / in-progress / done / paused
updated: 2026-10-15
related: [REQ-007, DES-007]       # 対応する REQ / DES の ID
frozen_tests:     # 凍結したテストファイル（リポジトリ直下からのパス）。凍結時に追記する（TEST-04）
  - tests/test_shapes.py
  - tests/test_cli.py
---
# TASK-010 REQ-007 の設計

> 以下の4セクション（現在のフェーズ〜未解決事項）は上書き更新する。「作業ログ」だけは追記のみ（DOC-11）。

## 現在のフェーズ
> 探索 / 計画 / 実装（Red / Green / Refactor）/ レビュー のどこにいるか。

完了

## 完了したこと

- PLAN-19 に当たる判断はなく、質問は 0 件。
- 試作（scratchpad の mobius_proto.py。プロジェクトには入れない）: R = 2/3、w = 1/3 の帯を、中心線に沿う向き × 幅の向きの点の数を変えて比べた。計算時間は回転角 0、幅 80・高さ 24 の1フレームを5回計った最短である。
  - 300 × 30（9000 点）: 0.012 秒。回転角 (0, 0)、(0.5, 0.3)、(1.2, 0.7)、(2.0, 1.0) のフレームに目立つ穴はなかった。
  - 400 × 40（16000 点）: 0.022 秒。
  - 500 × 50（25000 点）: 0.033 秒。
  - どれも一番遠い点の距離は 1.0 だった。
  - 面の向きは u = 0 で (0, 0, −1)、u = 2π で (0, 0, 1) だった。
  - 中心線の上で 1000 分割して1周したとき、隣り合う面の向きの内積の最小は 0.99998 だった。
  - 400 × 40 の全点で、帯の幅の向きと面の向きの内積の絶対値は最大 3e-16 で、中心線の円からの距離は最大 1/3 だった。中心線の円に沿う向きとの内積は最大 0.16 で 0 にならないので、test-items.md #7 には使わなかった。
- DES-007（変更するファイル3つ: src/spin/shapes.py、tests/test_shapes.py、tests/test_cli.py）と、test-items.md の DES-007 の見出し（13 項目）を作成した。
- REQ-007 の受け入れ基準の割り当て（PLAN-13）:
  - 基準 1: DES-007 #1〜#3、#13。
  - 基準 2: DES-007 #1・#7・#8・#9・#12。REQ-001 基準 1〜5 は、DES-001 の全図形の項目で確かめる。
  - 基準 3: DES-007 #5・#6。
  - DES-004 から回された REQ-004 基準 1 の `mobius-strip` の部分: DES-007 #2。
- architecture.md と glossary.md は変えない（`mobius_strip` は登録済み）。

## 次の一手
> 再開したセッションが最初に行うこと。再開する Skill（引数を含む）と手順の番号、最初に行う1つの具体的な行動を書く（DOC-21）。

なし（完了）

## 未解決事項

- 残した P2（test-reviewer r1）: (1) tests/test_shapes.py・tests/test_cli.py のモジュールの説明に DES-006・DES-007 がない (2) 「各成分を絶対誤差 1e-9 で比べる」処理が `_vectors_close` と `_matching_axis_direction` の2か所にある。
- 残した P2（code-reviewer r1）: `_unit_cross` の説明に「2つの向きが平行でないこと」という前提が書かれていない（平行だと ZeroDivisionError。帯の範囲では起きない）。

## 作業ログ
> 書き方は DOC-12、書くタイミングは DOC-13。新しい記録を下に足す。

- 2026-10-15 計画: DES-007 と test-items.md の DES-007 の見出し（12 項目）を作成。点の数と面の向きの性質を scratchpad で試作して確かめた。質問 0 件
- 2026-10-15 レビュー: plan-reviewer ラウンド1: 不合格 P0=0 P1=1 P2=1 保留0。P1（mobius_strip_point の v の境界値の項目がない）に対し test-items.md に #9 を足して番号を振り直し、DES-007 と TASK の参照を直した。P2（試作の記録との食い違い）も修正
- 2026-10-15 レビュー: plan-reviewer ラウンド2: 合格 P0=0 P1=0 P2=0 保留0
- 2026-10-15 レビュー: ユーザーが DES-007 を承認。DES-007 を final にした。DES が1つのため、この TASK で実装に進む（WF-08）
- 2026-10-15 実装（Red）: shapes.py に mobius_strip・mobius_strip_point のスタブを追加（SHAPES は変えない）、tests/test_shapes.py・tests/test_cli.py にテストを追加。新しい 9 件が失敗（アサーション 2、NotImplementedError 6、SystemExit(2) 1 は DES-007 の判断どおり）、既存 91 件と保持 3 件が成功。リント・フォーマット成功
- 2026-10-15 実装（Red）: test-reviewer ラウンド1: 合格 P0=0 P1=0 P2=2 保留0。テストを凍結（コミット 33c73d8）
- 2026-10-15 実装（Green）: shapes.py に mobius_strip_point・mobius_strip を実装し SHAPES に追加。テスト 103 件成功、カバレッジ 99.49%、リント・フォーマット成功。Refactor は不要と判断
- 2026-10-15 レビュー: code-reviewer ラウンド1: 合格 P0=0 P1=0 P2=1 保留0。P2 は未解決事項に記録
- 2026-10-15 完了: ユーザーが DES-007 #12・#13（人間確認）を OK と回答（#12 の秒数の報告はなし。手元の計測では mobius-strip 0.023 秒）。TASK を done にした
