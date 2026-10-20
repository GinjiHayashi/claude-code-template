---
name: quick-change
description: 小さな不具合修正、文言・設定の修正、資料だけの修正など、新しい要件や公開インタフェースの変更を伴わず、変更ファイルが3つ以下の作業を頼まれたときに使う。リリース済みの main の緊急修正（hotfix）は `hotfix <変更内容>` で行う。
argument-hint: "[hotfix] <変更内容>"
---
# 軽微な変更

対象: `$ARGUMENTS`（変更内容。`hotfix` で始まれば本番の緊急修正）。基準は WF-17〜19、hotfix は GIT-60・61。

## 準備
1. 未読なら（圧縮で内容が消えた場合も）`docs/guidelines/workflow.md`、`docs/guidelines/testing.md`、`docs/guidelines/coding.md`、`docs/guidelines/documentation.md`、`docs/guidelines/git.md` を読む。
2. `bash .claude/scripts/task.sh begin --next '/quick-change の手順 3: 変更箇所を調べる' <ブランチ名> <ファイル名> <変更内容の要約>` で作業ブランチと TASK を作る。ブランチ名は `feature/change-<ファイル名>`。`hotfix` で始まり GIT-60 に当たる場合だけ `hotfix` を渡す（当たらなければ通常の軽微な変更として進める）。

## 探索と判定
3. 変更箇所と影響範囲を Explore サブエージェントで調べる。
4. WF-17 の3条件を判定して TASK に書く。1つでも満たさない場合や、不具合が要件・設計の誤りに由来する場合は、止めて同じブランチのまま `/plan-spec change <変更内容>` に切り替える（hotfix は切り替えず、ユーザーに判断を求める）。

## 資料だけの変更
5. 資料を直し、`/review-loop plan <直した資料>` でレビューして、合格したらコミットして「完了」へ進む。

## コードの変更
6. 不具合の修正なら、再現するテストを書く（DES の番号がなければ説明に不具合を書く）。追加したテストだけがアサーションで失敗し、既存のテストは成功することを確かめ、テストファイルだけをコミットする。`task.sh freeze` で凍結し、`task.sh log` で凍結コミットのハッシュを書く。
7. 修正し、tech.md のテスト、リント、フォーマット、ビルドをすべて成功させてコミットする。途中で WF-17 を満たさなくなったら 4 と同じく切り替える。
8. `/review-loop code` で、2 の起点のコミットからの差分をレビューし、終わったらコミットする。
9. 振る舞いが DES の記述と変わった場合は、DES と test-items.md を直して `/review-loop plan` でレビューする。

## 完了
10. PR 本文を最新にして `bash .claude/scripts/branch.sh ready` を実行する。変更内容、レビュー結果、人間確認が要る点を承認パケット（GIT-30。差分リンクは起点のコミットから）で示して確認を求める。返答の後に PR へのコメントも読む（GIT-32）。
11. TASK を `done` にしてコミットし、`bash .claude/scripts/branch.sh merge` でマージする。
12. hotfix の場合は、11 の後に続けて行う。(1) `main` のマージコミットに `/release` の手順 8 と同じくタグとリリースノートを付ける (2) hotfix ブランチに戻り、`develop` 向きの PR を `gh pr create --base develop` で作り、CI の成功を確かめてマージする。コンフリクトしたら hotfix ブランチに `git merge develop` で取り込んで解消し、テスト・リント・ビルドを成功させてから入れる (3) hotfix ブランチを削除する
