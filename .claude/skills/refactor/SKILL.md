---
name: refactor
description: プロジェクト全体のリファクタリングや、コードと資料の整合の点検を頼まれたときに使う。差分ではなくリポジトリ全体を点検し、承認を得てから、振る舞いを変えない修正だけを直す。仕様に関わる問題は変更要求の候補として残す。
argument-hint: "[点検するディレクトリ（省略時は全体）]"
allowed-tools: Bash(bash .claude/scripts/audit.sh)
---
# プロジェクト全体の点検（リファクタリング）

対象: `$ARGUMENTS`（空ならリポジトリ全体）。基準は refactoring.md（RF-）。

## 準備
1. 未読なら（圧縮で内容が消えた場合も）`docs/guidelines/refactoring.md`、`docs/guidelines/review.md`、`docs/guidelines/git.md` を読む。
2. ブランチ名を決める。`git fetch --prune origin` の後（origin がなければ省く）、`git branch -a --list 'feature/refactor-<今日の YYYYMMDD>*' 'origin/feature/refactor-<今日の YYYYMMDD>*'` に同じ名前があれば `-2`・`-3` の連番を付ける（GIT-06）。`bash .claude/scripts/task.sh begin <ブランチ名> refactor リファクタリング` で作業ブランチと TASK を作る。

## 診断
3. tech.md のテスト、リント、ビルドを実行する（RF-28）。失敗したら P0 の指摘にし、自動修正は行わない（RF-43）。
4. `bash .claude/scripts/audit.sh` で機械の観点の指摘を得る。
5. code-auditor と docs-auditor を並行して呼ぶ。渡すのは点検の対象（ディレクトリか「全体」）だけにする。
6. 3〜5 の指摘をまとめる。ルール ID のない P0・P1 と存在しない ID の指摘は除き、同じ箇所の重複は1件にする。
7. 各指摘を RF-40 で分類し、一覧と修正計画（直す順と、新しく足すファイル。RF-41）を TASK の「完了したこと」に書く。

## 承認
8. 一覧と修正計画を承認パケット（GIT-30。差分リンクは省く）で示して承認を求め、任意（P2）の指摘から直すものを選んでもらう。テストの整理の対象も示す（RF-42）。承認されなかった指摘は TASK の「未解決事項」に書く。

## 修正
9. テストの整理（RF-40 (2)）があれば、自動修正より先に TEST-24 の手順で行う。test-reviewer は `/review-loop test <テストファイル>` で呼び、変更の前後の比較であることを伝える。凍結は `task.sh freeze` で行う。
10. 自動修正を1件ずつ Edit / Write で直す。テストファイルは変えない。1件ごとに「テスト（全件）」を実行し、失敗したら戻して変更要求の候補に移す（RF-43）。
11. テスト、リント、フォーマット、ビルドをすべて成功させてコミットする。
12. `/review-loop` でレビューする。コードは `code`（起点のコミットからの差分）、資料は `plan`。終わったらコミットする。

## 完了
13. 変更要求の候補を TASK の「未解決事項」に一覧で書く（RF-45）。
14. PR 本文を最新にして `bash .claude/scripts/branch.sh ready` を実行し、直した内容、レビュー結果、変更要求の候補を承認パケット（差分リンクは起点のコミットから）で示して確認を求める。候補を直す場合は1件ずつ `/plan-spec change` で進めると伝える。
15. TASK を `done` にしてコミットし、`bash .claude/scripts/branch.sh merge` でマージする。
