---
name: kickoff
description: 新しいプロジェクトの開発を始めるとき、または docs/project/overview.md か tech.md が存在しない・未記入のときに使う。概要と技術・環境をユーザーと1問ずつ作る。
---
# 開発開始

基準は PLAN-01〜04・07〜12・26・27、完了条件は WF-05。

## 準備
1. 未読なら（圧縮で内容が消えた場合も）`docs/guidelines/planning.md`、`docs/guidelines/documentation.md`、`docs/guidelines/git.md` を読む。
2. `bash .claude/scripts/task.sh begin feature/setup kickoff 開発開始` で作業ブランチと TASK を作る（develop がなければ、README の準備をユーザーに頼んで止まる）。

## テンプレートの用意
3. `docs/project/` に overview.md、tech.md、glossary.md がなければ、`docs/guidelines/templates/` からコピーする。
4. コピーした場合は、ユーザーに「各見出しの `（未記入）` を書き換えてほしい。全部埋めなくてよい」と伝え、記入が終わるまで待つ。

## 空欄を埋める
5. overview.md と tech.md で `（未記入）` が残る見出しを列挙する。既存のコードや資料があれば、事実を Explore サブエージェントで調べて質問の前提にする。
6. 5 の見出しを質問の一覧として示し、1つずつ質問して埋める。回答ごとに TASK に記録する（PLAN-07・08）。「未定」は未決事項に移す。
7. tech.md の「開発コマンド」は全操作にコマンドか「なし」が入るまで続ける。続けて `.github/workflows/ci.yml` の「言語の実行環境の準備」の印の間を、tech.md の言語・版に合う公式の setup 用 Action（コミット SHA で固定し、版をコメントに書く。各 step に `if: steps.scope.outputs.skip != 'true'` を付ける）に書き換える。準備が要らなければ「不要」と書く。

## ブラッシュアップ
8. 見出しをまたいで不足・矛盾・考慮漏れを洗い出し、一覧を示してから1つずつ質問する（PLAN-03・07・08・10）。
9. overview.md に出てくる固有の用語を glossary.md に登録し、定義と「コード上の名前」（英語）を推奨案で決める（PLAN-12）。DOC-16 を満たす判断は ADR に記録する。

## 完了
10. コミットし、`bash .claude/scripts/branch.sh pr` でプッシュと下書き PR を作る。承認パケット（GIT-30）で承認を求める。glossary.md の「コード上の名前」と ci.yml の準備も承認の対象に含め、差分リンクは起点のコミットからにする。返答の後に PR へのコメントも読む（GIT-32）。
11. 承認されたら3つのファイルを `status: final` にし、TASK を `done` にしてコミット・プッシュする。PR はマージしない（要件定義と同じブランチで続ける）。
12. 次は `/plan-spec` で要件定義に進むと伝える。
