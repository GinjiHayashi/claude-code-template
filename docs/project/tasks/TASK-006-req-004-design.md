---
status: done      # todo / in-progress / done / paused
updated: 2026-10-15
related: [REQ-004, DES-004]       # 対応する REQ / DES の ID
frozen_tests:     # 凍結したテストファイル（リポジトリ直下からのパス）。凍結時に追記する（TEST-04）
  - tests/test_cli.py
---
# TASK-006 REQ-004 の設計

> 以下の4セクション（現在のフェーズ〜未解決事項）は上書き更新する。「作業ログ」だけは追記のみ（DOC-11）。

## 現在のフェーズ
> 探索 / 計画 / 実装（Red / Green / Refactor）/ レビュー のどこにいるか。

完了

## 完了したこと

- 既存の事実: argparse の choices は誤った名前に対し、選べるすべての名前を標準エラー出力に書いて終了コード 2 で終わる（Python 3.12 で確認）。PLAN-19 に当たる判断はなく、質問は 0 件。
- DES-004（作成ファイル 2 つ: src/spin/cli.py、tests/test_cli.py）と test-items.md の DES-004 の見出しを作成。REQ-004 の基準 1〜5 はすべて test-items.md のどれかの項目で検証される（PLAN-13）。
- glossary.md に「起動オプション（launch_options）」を追記した（PLAN-17）。

## 次の一手
> 再開したセッションが最初に行うこと。再開する Skill（引数を含む）と手順の番号、最初に行う1つの具体的な行動を書く（DOC-21）。

なし（次の作業は /plan-spec REQ-005 で設計）

## 未解決事項

- 残した P2（plan-reviewer r1）: architecture.md の「構成要素と境界」の `spin.cli` の「作る DES」の欄が「REQ-004 の設計で決める」のまま（DES-004 に直すとよい）。次に architecture.md を改訂するときに直す。
- 残した P2（plan-reviewer r2）: (1) DES-004 の概要と入力の説明で「起動オプション」を解析前の文字列の並びにも使っている（glossary では解析後の値） (2) 位置引数の argparse 上の名前が DES に書かれていない（実装では `shape_name` にする） (3) 極端に長い入力（20 桁の数字、1 万文字の図形の名前）の敵対的入力の項目がない。
- 残した P2（test-reviewer r3・r4）: (1) DES-004 の誤りの表の「知らないオプション」の行に、知らないオプションに続く値が図形の名前として読まれ `invalid choice` になる場合があることが書かれていない（次に DES-004 を改訂するときに注記する） (2) tests/test_cli.py の #9 は標準エラー出力の中身を確かめていない（`usage: spin` を含むことを確かめるとよい）。
- 残した P2（code-reviewer r1）: (1) `_positive_integer` で `int(text)` を2回呼んでいる (2) 描くフレーム数の既定値 `None` だけ定数にしていない（DES-004 のデータ構造の記述と揃っていない）。
- DES-004 の未決事項: 数値の上限がない（極端な値で再生が止まったようになりうる）。上限を設けるには REQ-004 の変更要求が要る。

## 作業ログ
> 書き方は DOC-12、書くタイミングは DOC-13。新しい記録を下に足す。

- 2026-10-15 計画: DES-004 と test-items.md の DES-004 の見出し（14 項目）を作成。glossary.md に起動オプションを追記。質問 0 件
- 2026-10-15 レビュー: plan-reviewer ラウンド1: 不合格 P0=0 P1=2 P2=4 保留0。P1 2件（-h の出口、glossary の updated）と P2 3件（略記、上限を未決事項に、対応要件の範囲）を修正。P2 1件（architecture.md の欄）は未解決事項に記録。test-items の DES-004 は 15 項目に
- 2026-10-15 レビュー: plan-reviewer ラウンド2: 合格 P0=0 P1=0 P2=4 保留0。P2 は未解決事項に記録
- 2026-10-15 レビュー: ユーザーが DES-004 を承認し final にした。DES が1つのため、この TASK で実装に進む（WF-08）
- 2026-10-15 実装（Red）: スタブ src/spin/cli.py と tests/test_cli.py を作成。新しい 36 件が NotImplementedError で失敗、既存 33 件は成功（Red 確認）。リント・フォーマット成功
- 2026-10-15 実装（Red）: test-reviewer ラウンド1: 不合格 P0=0 P1=1 P2=2 保留0。P1（#6 のケース id に項目番号）と P2 2件を修正。Red 再確認: 新しい 36 件が NotImplementedError で失敗、既存 33 件成功
- 2026-10-15 実装（Red）: test-reviewer ラウンド2: 不合格 P0=0 P1=1 P2=2 保留0。P1（使い方の行で常に成り立つ広いアサーション。理由の行 argument <option>: 正の整数 を照合）と P2 2件（invalid choice の行、#9 の理由）を修正。Red 再確認: 新しい 36 件が NotImplementedError で失敗、既存 33 件成功
- 2026-10-15 実装（Red）: test-reviewer ラウンド3: 不合格 P0=1 P1=0 P2=1 保留0（#9 の理由の照合が DES どおりの実装でも失敗する。ラウンド2で足した照合が原因）。REV-07 で停止しユーザー判断: (b) 理由の照合をやめる。修正し、Red 再確認: 新しい 36 件が NotImplementedError で失敗、既存 33 件成功
- 2026-10-15 実装（Red）: test-reviewer 確認ラウンド（r4）: 合格 P0=0 P1=0 P2=1 保留0。テストを凍結（コミット 89ed6d2）
- 2026-10-15 実装（Green）: src/spin/cli.py を実装。テスト 69 件成功、カバレッジ 99.17%、リント・フォーマット成功。Refactor は不要と判断
- 2026-10-15 レビュー: code-reviewer ラウンド1: 合格 P0=0 P1=0 P2=2 保留0。P2 は未解決事項に記録
- 2026-10-15 完了: 人間確認 DES-004 #15: ユーザーの環境で invalid choice の表示と exit=2 を確認。DES-004 の実装を完了
