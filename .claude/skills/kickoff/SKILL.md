---
name: kickoff
description: 新しいプロジェクトの開発を始めるとき、または docs/project/overview.md か tech.md が存在しない・未記入のときに使う。概要と技術・環境をユーザーと1問ずつ作る。
---
# 開発開始

## 準備
1. `docs/guidelines/planning.md`（PLAN-01〜07、PLAN-16・17）と `docs/guidelines/documentation.md` を読む。
2. `docs/guidelines/templates/task.md` から TASK ファイル（タスク名「開発開始」）を作り、`status: in-progress` にする（WF-08）。

## テンプレートの用意
3. `docs/project/overview.md`、`docs/project/tech.md`、`docs/project/glossary.md` がなければ、`docs/guidelines/templates/` の同名ファイルをコピーする。
4. コピーした場合は、ユーザーに「各見出しの `（未記入）` を書き換えてほしい。全部埋めなくてよい」と伝え、記入が終わるまで待つ。

## 空欄を埋める
5. 2つのファイルで `（未記入）` が残っている見出しを列挙する（DOC-17）。
6. 既存のコードや資料がある場合は、事実を Explore サブエージェントで調べ、質問の前提にする（PLAN-02）。
7. 空欄の見出しを1つずつ質問して埋める（PLAN-01）。ユーザーの回答を、その見出しの `（未記入）` と置き換える。「未定」は未決事項に移す（PLAN-04）。
8. tech.md の「開発コマンド」は、全操作にコマンドか「なし」が入るまで続ける（PLAN-07）。

## ブラッシュアップ
9. 空欄がなくなったら、見出しをまたいで不足・矛盾・考慮漏れを探し、1つずつ指摘して質問する（PLAN-03、PLAN-06）。
10. 決まった用語は glossary.md に、DOC-15 を満たす判断は ADR に記録する（PLAN-16、PLAN-17）。

## 完了
11. ユーザーに承認を求める（WF-04）。
12. 承認されたら、2つのファイルの `status` を `final`、`updated` を今日の日付にし、TASK を `done` にして作業ログを書く。
13. 次は `/plan-spec` で要件定義に進むと伝える。
