---
name: quick-change
description: 小さな不具合修正、文言・設定の修正、資料だけの修正など、新しい要件や公開インタフェースの変更を伴わず、変更ファイルが3つ以下の作業を頼まれたときに使う。リリース済みの main の緊急修正（hotfix）は `hotfix <変更内容>` で行う。
argument-hint: "[hotfix] <変更内容>"
---
# 軽微な変更

対象: `$ARGUMENTS`（変更内容の説明。`hotfix` で始まれば本番の緊急修正）

## 準備
1. この会話でまだ読んでいない（圧縮などで内容が残っていない場合を含む）ときだけ、`docs/guidelines/workflow.md`（WF-12〜16）、`docs/guidelines/testing.md`、`docs/guidelines/coding.md`、`docs/guidelines/documentation.md`、`docs/guidelines/git.md` を読む。
2. 作業ブランチに入る（GIT-03・04）。`hotfix` で始まる場合は、GIT-60 に当たるか確かめてから `bash .claude/scripts/branch.sh start hotfix` を使う（当たらなければ通常の軽微な変更として進める）。それ以外は `bash .claude/scripts/branch.sh start feature/change-<次の task.sh new に渡すファイル名>` を使う。`task.sh new` で TASK ファイル（タスク名は変更内容の要約）を作り、`task.sh status` で `in-progress` にする（WF-08）。起点のコミットを `task.sh log` で作業ログに書き、コミットする（GIT-10 (1)、GIT-12）。

## 探索と判定
3. 変更箇所と影響範囲を Explore サブエージェントで調べる（WF-03）。
4. WF-14 の3条件を判定し、結果を TASK に書く。1つでも満たさなければ止めて、変更要求（`/plan-spec change <変更内容>`）に切り替える（WF-16、WF-18）。不具合が要件・設計の誤りに由来する場合も切り替える（WF-10、WF-11）。切り替えるときは、同じブランチのまま続ける（hotfix は切り替えず、ユーザーに判断を求める）。

## 資料だけの変更
5. 資料を修正する（DOC ルールに従う）。
6. `/review-loop` Skill を使い、種別 `plan`、対象を変更した資料としてレビューする。合格したらコミットし（GIT-10 (2)）、「完了」へ進む。

## コードの変更
7. 不具合の修正なら、不具合を再現するテストを書き（テスト名と説明は TEST-09、DES の番号がなければ説明に再現する不具合を書く）、tech.md の「テスト（全件）」で、追加したテストだけがアサーション失敗で失敗し、既存のテストは成功することを確認する（失敗理由の基準は TEST-03）。テストファイルだけをコミットし（GIT-12）、`task.sh freeze` で TASK の `frozen_tests` にそのパスを、`task.sh log` で作業ログに凍結コミットのハッシュを書いて凍結する（TEST-04）。
8. 修正する。テストファイルは変更しない（TEST-04）。
9. tech.md のテスト、リント、フォーマット、ビルドのコマンドを実行し、すべて成功させる（TEST-06、REV-14）。成功したらコミットする（GIT-10 (4)）。
10. 変更中に WF-14 の条件を満たさなくなったら、止めて変更要求（`/plan-spec change <変更内容>`）に切り替える（WF-16、WF-18）。
11. `/review-loop` Skill を使い、種別 `code`、対象を変更前のコミットからの git diff（テストファイルを含む）としてレビューする。終わったらコミットする（GIT-10 (5)）。
12. 振る舞いが DES の記述と変わった場合は DES と test-items.md を更新し、`/review-loop` の種別 `plan` でレビューする。

## 完了
13. `bash .claude/scripts/branch.sh pr` でプッシュと下書き PR の作成を行い、PR 本文を最新にして下書きを解除し、CI の結果を待つ（GIT-20〜22、GIT-25）。変更内容、レビュー結果、人間確認が必要な点を承認パケット（GIT-30）で示して確認を求める（WF-12）。差分リンクは起点のコミットからの比較とする（GIT-31）。返答を受けたら PR へのコメントも読む（GIT-32）。
14. TASK を `done` にし、作業ログを書き、コミット・プッシュして、CI の成功を確かめてから PR をマージする（GIT-10 (6)、GIT-23、GIT-25）。hotfix の場合は GIT-61 の (1)〜(3) を行う。
