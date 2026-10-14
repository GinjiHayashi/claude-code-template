---
status: done      # todo / in-progress / done / paused
updated: 2026-10-15
related: [REQ-001, DES-001]       # 対応する REQ / DES の ID
frozen_tests:     # 凍結したテストファイル（リポジトリ直下からのパス）。凍結時に追記する（TEST-04）
  - tests/test_rendering.py
  - tests/test_shapes.py
---
# TASK-003 REQ-001 の設計

> 以下の4セクション（現在のフェーズ〜未解決事項）は上書き更新する。「作業ログ」だけは追記のみ（DOC-11）。

## 現在のフェーズ
> 探索 / 計画 / 実装（Red / Green / Refactor）/ レビュー のどこにいるか。

完了

## 完了したこと

- 既存コードはない（src・tests・pyproject.toml なし）ため Explore は不要。PLAN-19 に当たる判断はなく、質問は 0 件。
- architecture.md をテンプレートから作成（WF-02）。
- DES-001（REQ-001 の基準 1〜10 をすべて担う、作成ファイル 5 つ）と test-items.md の DES-001 の見出しを作成。基準 1〜10 はすべて test-items.md のどれかの項目で検証される（PLAN-13）。
- TASK-002 の未解決事項「0 と 2π の一致」は、DES-001 で角を 2π で割った余りにする設計で対応した。立方体の正面の文字は、REQ-006 の設計で扱う。
- glossary.md に「近さ（closeness）」を追記した（PLAN-17）。

## 次の一手
> 再開したセッションが最初に行うこと。再開する Skill（引数を含む）と手順の番号、最初に行う1つの具体的な行動を書く（DOC-21）。

なし（次の作業は /plan-spec REQ-002 で設計）

## 未解決事項

- 残した P2（テストのレビュー）: test-items.md の DES-001 の前文は「パラメータ化して確かめる」だが、テストは関数の中で SHAPES を順に確かめている（収集時に SHAPES を参照するとスタブで収集エラーになり、Red と認められないため）。表記を直すかは任意。
- 残した P2（テストのレビュー）: tests/test_rendering.py の #4 は、メッセージに値が含まれるかを部分文字列で照合しているため、「幅 80・高さ 0」で `0` が `80` の一部にも一致する。
- 残した P2（テストのレビュー r2）: tests/test_shapes.py の #6 の docstring から「空白以外もある」を削ったため、アサーションの一部（空白以外の文字が1つ以上ある）が説明に表れていない。書き足すと行の長さ 88 を超えるため残した。
- 残した P2（コードのレビュー r2、DES-001 との記述のずれ）: (1) `.python-version`（uv python pin 3.12 が生成）が DES-001 の「数えないファイル」にない (2) pyproject.toml の `[tool.hatch.build.targets.wheel] packages` と `[tool.ruff] include`（ユーザー承認済み）が DES-001 の pyproject.toml の記述にない (3) DES-001 の式 `width / 4` をコードは `width / 2 / _CHAR_ASPECT` と書いている。DES-001 は final のため、次に DES-001 を改訂する機会に反映する。
- 残した P2（コードのレビュー r2、コード）: rendering.py の三角関数の値の型 `tuple[float, float, float, float]` を2か所に書いている（型の別名にするとよい）。`render_frame` の段落のコメント「入力の検証」を目的の形（例: 幅と高さが 1 以上であることを確かめる）にするとよい。

## 作業ログ
> 書き方は DOC-12、書くタイミングは DOC-13。新しい記録を下に足す。

- 2026-10-14 計画: architecture.md、DES-001、test-items.md（DES-001 の項目 27 件）を作成。質問 0 件
- 2026-10-14 レビュー: plan-reviewer ラウンド1: 不合格 P0=0 P1=6 P2=3 保留0。P1 6件と P2 3件を修正（test-items は項目 29 件に）
- 2026-10-14 レビュー: plan-reviewer ラウンド2: 不合格 P0=0 P1=4 P2=4 保留0。P1 4件と P2 4件を修正（test-items は項目 31 件に）
- 2026-10-14 レビュー: plan-reviewer ラウンド3: 不合格 P0=0 P1=1 P2=2 保留0。REV-07 のラウンド上限に達したため修正を止め、ユーザーに判断を求める
- 2026-10-14 レビュー: ユーザー判断: ラウンド3の残り3件（P1 1・P2 2）を直して確認ラウンドを1回行う。修正し、差分を .claude/review/TASK-003-r4.diff に保存
- 2026-10-14 レビュー: plan-reviewer 確認ラウンド（r4）: 合格 P0=0 P1=0 P2=0 保留0
- 2026-10-14 レビュー: ユーザーが DES-001・architecture.md を承認し final にした。DES が1つのため、この TASK で実装に進む（WF-08）
- 2026-10-14 実装（Red）: pyproject.toml・.gitignore・.python-version（3.12 に固定）とスタブ、tests/test_rendering.py・tests/test_shapes.py を作成。全 33 件が NotImplementedError で失敗（Red 確認）。スタブの定数・SHAPES はモジュールの __getattr__ で、データクラスは生成時に NotImplementedError を出す形にした（定数のテストがスタブで成功しないようにするため）
- 2026-10-14 実装（Red）: test-reviewer ラウンド1: 合格 P0=0 P1=0 P2=2 保留0。テストを凍結（コミット 2079ec5）
- 2026-10-14 実装（Green）: rendering.py・shapes.py を実装。テスト 33 件成功、カバレッジ 99%。リントで凍結テスト tests/test_shapes.py の docstring 2 か所が E501（行の長さ超過）、ruff format . が docs/guidelines/testing.md のコード例も整形対象にする問題を検出。TEST-05 によりユーザーに報告して停止
- 2026-10-14 実装（Green）: ユーザーが凍結の解除を承認（TEST-05）: tests/test_shapes.py の docstring 2 か所（#6・#11）を E501 に収まるよう短くする。frozen_tests から2ファイルを外した。あわせて ruff の対象を include で Python に限ることも承認
- 2026-10-14 実装（Red）: テストの説明 2 か所を短くし、スタブ（scratchpad に置き PYTHONPATH で優先）に対して全 33 件が NotImplementedError で失敗することを再確認。test-reviewer ラウンド2: 合格 P0=0 P1=0 P2=1 保留0。再凍結（コミット 2e7370a）
- 2026-10-14 レビュー: code-reviewer ラウンド1: 不合格 P0=0 P1=3 P2=3 保留0。P1 3件（CODE-25 段落の長さ 2件、CODE-16 マジックナンバー）と P2 3件を修正。テスト 33 件成功、リント・フォーマット成功
- 2026-10-14 レビュー: code-reviewer ラウンド2: 合格 P0=0 P1=0 P2=5 保留0。P2 は未解決事項に記録
- 2026-10-15 完了: ユーザーが人間確認 #31（ドーナツの見た目）を OK と確認。DES-001 の実装を完了
