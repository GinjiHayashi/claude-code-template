---
status: done      # todo / in-progress / done / paused
updated: 2026-10-15
related: [REQ-005, DES-005]       # 対応する REQ / DES の ID
frozen_tests:     # 凍結したテストファイル（リポジトリ直下からのパス）。凍結時に追記する（TEST-04）
  - tests/test_animation.py
  - tests/test_main.py
---
# TASK-007 REQ-005 の設計

> 以下の4セクション（現在のフェーズ〜未解決事項）は上書き更新する。「作業ログ」だけは追記のみ（DOC-11）。

## 現在のフェーズ
> 探索 / 計画 / 実装（Red / Green / Refactor）/ レビュー のどこにいるか。

完了

## 完了したこと

- PLAN-19 に当たる判断はなく、質問は 0 件。
- DES-005（作成ファイル 4 つ: src/spin/animation.py、src/spin/__main__.py、tests/test_animation.py、tests/test_main.py）と test-items.md の DES-005 の見出しを作成。REQ-005 の基準 1〜7 と、DES-004 から回した REQ-004 の基準 4・5（起動のコマンドを通した確認）は、すべて test-items.md のどれかの項目で検証される（PLAN-13）。
- architecture.md を改訂（PLAN-23）: `spin.__main__` → `spin.shapes` を足し、`spin.animation` → `spin.shapes` を消した。「作る DES」の欄、pyproject.toml の注記、`spin.__main__` のテストファイル名も更新（TASK-005・TASK-006 で残した P2 の対応を含む）。status を draft に戻した。
- glossary.md に「再生環境（playback_environment）」を追記した（PLAN-17）。
- architecture.md の改訂の影響一覧（PLAN-23、PLAN-25 の形）:
  1. REQ: 追加・改訂・削除なし。
  2. DES: DES-001 は改訂（判断「依存の向き」が改訂後の依存の向きと合わないため。あわせて TASK-003 の P2 を反映。振る舞いは変えない）。DES-004 は影響なし（`spin.cli` → `spin.shapes` の依存だけに触れ、その向きは変わらない）。DES-002・DES-003 は影響なし（モジュールの依存に触れない）。
  3. テストファイル: 該当なし（DES-001 の項目は変わらず、tests/test_rendering.py・tests/test_shapes.py・tests/test_cli.py は変更しない）。
  4. 資料の見出し: architecture.md の「構成要素と境界」「依存の向き」「ディレクトリ構成」「命名規則」。glossary.md の「再生環境」の行。

## 次の一手
> 再開したセッションが最初に行うこと。再開する Skill（引数を含む）と手順の番号、最初に行う1つの具体的な行動を書く（DOC-21）。

なし（完了）

## 未解決事項

- 残した P2（plan-reviewer r3）:
  1. DES-001 の判断「標準ライブラリの使い方」の採用案が、architecture.md の許可リストの方式と食い違っている（改訂前からの不一致）。
  2. DES-001 の `related` に DES-005 がない。
  3. architecture.md の `spin.animation` の責務に「時刻の取得」の差し替えが書かれていない。
  4. DES-005 で、Ctrl+C を正常に戻す範囲が、インタフェース（どこでも）と処理方針（繰り返しの中だけ）で食い違っている。実装は処理方針どおりにする（`CLEAR + HIDE` を書く間と、点を作る間の Ctrl+C は捕まえない）。
  5. この TASK の「完了したこと」の architecture.md の改訂内容に、`spin.animation` → `spin.cli` の追加が書かれていない（影響一覧の下の記述と作業ログには書いてある）。
- 残した P2（test-reviewer r1）: (1) エスケープシーケンスの定数を tests/test_animation.py と tests/test_main.py の両方に定義している (2) #7・#8 の `pytest.raises(RuntimeError)` が送出元を `match` で確かめていない (3) 実装が `KeyboardInterrupt` を捕まえ損ねると、#5・#6 で pytest のセッション全体が中断される（Green で中断が起きたら #5・#6 を疑う）。
- 残した P2（code-reviewer r2）: (1) `_write_frame` の説明に動詞が2つある（「カーソルを左上に戻してから書く」の形にするとよい） (2) 引数とループ変数の名前 `number` は `frame_number` の方が分かりやすい。

## 作業ログ
> 書き方は DOC-12、書くタイミングは DOC-13。新しい記録を下に足す。

- 2026-10-15 計画: DES-005 と test-items.md の DES-005 の見出し（16 項目）を作成。architecture.md を改訂（PLAN-23）。glossary.md に再生環境を追記。質問 0 件
- 2026-10-15 レビュー: plan-reviewer ラウンド1: 不合格 P0=0 P1=1 P2=3 保留0。P1（DES-001 の判断「依存の向き」が改訂後の architecture.md と合わない）に対し、DES-001 を draft に戻して改訂（PLAN-22・23。あわせて TASK-003 の P2: .python-version・pyproject の packages/include・式の形を反映）。P2 2件（偽の環境の既定値、try の範囲）を修正。P2 1件（pyproject の注記は TASK-005 の P2 への対応）はこのログで出どころを記録
- 2026-10-15 レビュー: plan-reviewer ラウンド2: 不合格 P0=0 P1=2 P2=3 保留0。P1 2件（animation → cli の依存を architecture.md に追加、影響一覧を TASK に記載）と P2 3件を修正
- 2026-10-15 レビュー: plan-reviewer ラウンド3: 合格 P0=0 P1=0 P2=5 保留0。P2 は未解決事項に記録
- 2026-10-15 レビュー: ユーザーが「進めて」と回答。DES-005・architecture.md の改訂・DES-001 の改訂の承認と受け取り、3つを final にした。DES が1つのため、この TASK で実装に進む（WF-08）
- 2026-10-15 実装（Red）: スタブ src/spin/animation.py・src/spin/__main__.py と tests/test_animation.py・tests/test_main.py を作成。新しい 14 件が NotImplementedError で失敗、既存 69 件成功（Red 確認）。リント・フォーマット成功
- 2026-10-15 実装（Red）: test-reviewer ラウンド1: 合格 P0=0 P1=0 P2=3 保留0。テストを凍結（コミット 03731d2）
- 2026-10-15 実装（Green）: src/spin/animation.py・src/spin/__main__.py を実装。テスト 83 件成功、カバレッジ 99.40%、リント・フォーマット成功。Refactor は不要と判断
- 2026-10-15 レビュー: code-reviewer ラウンド1: 不合格 P0=0 P1=2 P2=0 保留0。_draw_frame を _write_frame と _wait_rest_of_interval に分割（CODE-05・CODE-28）。テスト 83 件成功、リント・フォーマット成功
- 2026-10-15 レビュー: code-reviewer ラウンド2: 合格 P0=0 P1=0 P2=2 保留0。P2 は未解決事項に記録
- 2026-10-15 完了: ユーザーが DES-005 #16（人間確認）を OK と回答。TASK を done にした
