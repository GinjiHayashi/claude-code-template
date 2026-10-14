---
status: done      # todo / in-progress / done / paused
updated: 2026-10-15
related: []       # 対応する REQ / DES の ID
frozen_tests:     # 凍結したテストファイル（リポジトリ直下からのパス）。凍結時に追記する（TEST-04）
---
# TASK-008 リファクタリング

> 以下の4セクション（現在のフェーズ〜未解決事項）は上書き更新する。「作業ログ」だけは追記のみ（DOC-11）。

## 現在のフェーズ
> 探索 / 計画 / 実装（Red / Green / Refactor）/ レビュー のどこにいるか。

完了

## 完了したこと

- 診断（RF-28）: テスト 83 件成功（カバレッジ 99.41%）、リント・フォーマット成功、ビルドは「なし」。
- 指摘の一覧（audit.sh・code-auditor・docs-auditor をまとめたもの。RF-40 で分類）:
  - 自動修正:
    - A1 P1 RF-26（DOC-17）docs/project/overview.md:8: 記入の案内の引用に文字列「（未記入）」があり、機械判定に当たる。案内の文言を、その文字列を含まない形に直す（見出しの記述は変えない）。
  - 変更要求の候補:
    - C1 P1 RF-21（PLAN-13）: REQ-006・REQ-007 の受け入れ基準と、REQ-004 基準 1 の cube・mobius-strip の部分が、DES と test-items.md に割り当てられていない。原因は設計が済んでいないことであり、残作業の `/plan-spec REQ-006`・`/plan-spec REQ-007` で解消する。変更要求は要らない。
    - C2 P1 RF-22（PLAN-11）DES-005:35: インタフェース欄では Ctrl+C を正常に戻す範囲に限定がない。処理方針とコードは「繰り返しの中だけ」である。インタフェース欄を直す必要がある（TASK-007 の未解決事項 4）。
    - C3 P1 RF-30（DOC-01）DES-001:105 と architecture.md:30: 標準ライブラリの方針が食い違っている。DES-001 は禁止リスト方式で、architecture.md と test-items.md #29 は許可リスト方式である。DES-001 の判断を改訂する必要がある（TASK-007 の未解決事項 1）。
  - 任意（P2）:
    - O1 RF-10 tests/test_main.py・tests/test_animation.py: エスケープシーケンスの定数が二重に定義されている（テストの変更になるので、この点検では直せない）。
    - O2 RF-10 tests/test_rendering.py・tests/test_animation.py: 原点の点を作る補助関数が二重にある（テストの変更になるので、直せない）。
    - O3 RF-15 tests/ の各ファイル: 補助関数の docstring の有無がそろっていない（テストの変更になるので、直せない）。
    - O4 RF-10 src/spin/cli.py:10・src/spin/shapes.py:41: 文字列 "torus" が2か所にある（直すと shapes に公開の定数が増え、DES のインタフェースが変わるので、自動修正にならない）。
    - O5 RF-16 src/spin/cli.py:52: docstring に `--help` の SystemExit(0) が書かれていない。
    - O6 RF-19 src/spin/rendering.py:65・116: render_frame が点ごとに cos・sin を計算し直している。
    - O7 RF-18 pyproject.toml:15-17: hatchling が tech.md に書かれておらず、版の範囲もない。
    - O8 RF-27 docs/project/architecture.md:15: `spin.animation` の責務に、時刻の取得の差し替えが書かれていない。
- 修正計画（RF-41）: A1 → 承認された P2 の順に1件ずつ直す。新しく足すファイルはない。

## 次の一手
> 再開したセッションが最初に行うこと。再開する Skill（引数を含む）と手順の番号、最初に行う1つの具体的な行動を書く（DOC-21）。

なし（完了）

## 未解決事項

- 変更要求の候補（RF-45）:
  - C1 REQ-006・REQ-007 の受け入れ基準と、REQ-004 基準 1 の cube・mobius-strip の部分が未割り当てである。残作業の `/plan-spec REQ-006`・`/plan-spec REQ-007` で解消する（変更要求は要らない）。
  - C2 DES-005 のインタフェース欄の Ctrl+C の範囲を、処理方針に合わせて「繰り返しの中だけ」に直す（`/plan-spec change`）。
  - C3 DES-001 の判断「標準ライブラリの使い方」を、architecture.md の許可リスト方式に合わせて改訂する（`/plan-spec change`）。
- 承認されなかった P2: O1〜O4・O6・O7（内容は「完了したこと」の一覧のとおり）。
- 残した P2（plan-reviewer r1）: docs/guidelines/templates/overview.md の案内文に文字列「（未記入）」があり、次のプロジェクトでも audit.sh の RF-26 に当たる。テンプレートを直すのは別のタスクとする。

## 作業ログ
> 書き方は DOC-12、書くタイミングは DOC-13。新しい記録を下に足す。

- 2026-10-15 準備: 変更前のコミット 03731d2（src・docs・pyproject.toml などは未コミットのため、変更前の作業ツリーを scratchpad の refactor-base に控えた）
- 2026-10-15 診断: テスト・リント・フォーマット成功。audit.sh P1=1、code-auditor 合格 P0=0 P1=0 P2=7、docs-auditor 不合格 P0=0 P1=3 P2=1。分類: 自動修正1、変更要求の候補3（うち1件は残作業で解消）、任意8
- 2026-10-15 計画: 質問1（修正計画の承認）: ユーザーが「承認する」と回答。A1 を直し、C1〜C3 を未解決事項に記録する
- 2026-10-15 計画: 質問2（P2 の選択）: ユーザーが O5・O8 を選択。O1〜O4・O6・O7 は未解決事項に残す
- 2026-10-15 レビュー: code-reviewer ラウンド1: 合格 P0=0 P1=0 P2=0 保留0。plan-reviewer ラウンド1: 不合格 P0=0 P1=1 P2=2 保留0。P1（overview.md の updated）と P2 1件（案内の文言で DOC-17 を参照）を修正。P2 1件（テンプレートの案内文）は未解決事項に記録
- 2026-10-15 レビュー: plan-reviewer ラウンド2: 合格 P0=0 P1=0 P2=0 保留0
- 2026-10-15 完了: A1・O5・O8 を修正。テスト 83 件成功、リント・フォーマット成功、audit.sh 指摘なし。変更要求の候補 C1〜C3 を未解決事項に記録。TASK を done にした
