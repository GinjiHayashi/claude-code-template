---
name: kickoff
description: 新しいプロジェクトの開発を始めるとき、または docs/project/overview.md か tech.md が存在しない・未記入のときに使う。概要と技術・環境をユーザーと1問ずつ作る。
---
# 開発開始

## 準備
1. この会話でまだ読んでいない（圧縮などで内容が残っていない場合を含む）ときだけ、`docs/guidelines/planning.md`（PLAN-01〜07、PLAN-16・17・21・26・27）、`docs/guidelines/documentation.md`、`docs/guidelines/git.md` を読む。
2. `bash .claude/scripts/branch.sh start feature/setup` で作業ブランチに入る（GIT-03・04。develop がなければ、README 2.1 の準備をユーザーに頼んで止まる）。`task.sh new kickoff 開発開始` で TASK ファイルを作り、`task.sh status` で `in-progress` にする（WF-08）。出力された起点のコミットを `task.sh log` で作業ログに書き、コミットする（GIT-10 (1)、GIT-12）。

## テンプレートの用意
3. `docs/project/overview.md`、`docs/project/tech.md`、`docs/project/glossary.md` がなければ、`docs/guidelines/templates/` の同名ファイルをコピーする。
4. コピーした場合は、ユーザーに「各見出しの `（未記入）` を書き換えてほしい。全部埋めなくてよい」と伝え、記入が終わるまで待つ。

## 空欄を埋める
5. 2つのファイルで `（未記入）` が残っている見出しを列挙する（DOC-17）。
6. 既存のコードや資料がある場合は、事実を Explore サブエージェントで調べ、質問の前提にする（PLAN-02）。
7. 最初の質問の前に、5 の見出しを質問の一覧として示す（PLAN-26）。空欄の見出しを1つずつ質問して埋め、回答ごとに TASK に記録する（PLAN-01、PLAN-27）。ユーザーの回答を、その見出しの `（未記入）` と置き換える。「未定」は未決事項に移す（PLAN-04）。
8. tech.md の「開発コマンド」は、全操作にコマンドか「なし」が入るまで続ける（PLAN-07）。続けて、tech.md の「言語・バージョン」と「パッケージ管理」をもとに、`.github/workflows/ci.yml` の「言語の実行環境の準備」の印の間の `（未記入）` を、言語を入れる手順（その言語の公式の setup 用 Action など。版は tech.md に合わせる）に置き換える（GIT-24）。準備が要らなければ「不要」と書く。使う Action はコミット SHA で固定し、版をコメントに書く。

## ブラッシュアップ
9. 空欄がなくなったら、見出しをまたいで不足・矛盾・考慮漏れをすべて洗い出す。質問の一覧を示してから（PLAN-26）、1つずつ指摘して質問し、回答ごとに TASK に記録する（PLAN-03、PLAN-06、PLAN-27）。
10. overview.md に出てくるプロジェクト固有の用語を glossary.md に登録し、定義と「コード上の名前」（英語。ローマ字は使わない）を推奨案で決める（PLAN-17、PLAN-21、DOC-04）。DOC-15 を満たす判断は ADR に記録する（PLAN-16）。

## 完了
11. コミットし（GIT-10 (2)）、`bash .claude/scripts/branch.sh pr` でプッシュと下書き PR の作成を行う（GIT-20・21）。承認パケット（GIT-30）でユーザーに承認を求める（WF-04）。glossary.md の「コード上の名前」と ci.yml の準備の手順も承認の対象として示す。差分リンクは起点のコミットからの比較とする（GIT-31）。返答を受けたら PR へのコメントも読む（GIT-32）。
12. 承認されたら、3つのファイルの `status` を `final`、`updated` を今日の日付にし、TASK を `done` にして作業ログを書き、コミットしてプッシュする（GIT-10 (6)）。PR はマージしない（要件定義と同じブランチで続ける。GIT-03）。
13. 次は `/plan-spec` で要件定義に進むと伝える。
