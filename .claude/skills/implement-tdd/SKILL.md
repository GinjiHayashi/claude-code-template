---
name: implement-tdd
description: 承認済みの設計（DES）を実装するときに使う。テストとスタブ作成、Red の確認、テストのレビュー、Green、Refactor、コードのレビューまでを TDD で行う。
argument-hint: "<DES-ID>"
---
# 実装（TDD）

対象: `$ARGUMENTS`（DES の ID）。サイクルの基準は TEST-01〜10、コードの基準は coding.md。

## 準備
1. 未読なら（圧縮で内容が消えた場合も）`docs/guidelines/testing.md`、`docs/guidelines/coding.md`、`docs/guidelines/git.md` を読む。
2. 対象の DES、対応する REQ、`docs/project/test-items.md` の対象 DES の見出し、`docs/project/architecture.md`、`docs/project/tech.md` を読む。
3. 変更のブランチ（`feature/change-`）にいなければ `bash .claude/scripts/branch.sh start feature/REQ-xxx-<名前>` で対象 REQ のブランチに入る。対象 DES の TASK を `task.sh status <TASK-ID> in-progress` にする（コミットは 8 で行う。GIT-10）。
   - 振る舞いを削除するだけの DES（TEST-10）は 4〜9 を省き、「既存の振る舞いへの影響」に挙げたテストとコードを削除して 11 に進む。完了時に DES を `retired` にし、test-items.md の見出しに `（retired）` を付ける（PLAN-24）。

## テストとスタブ
4. DES のインタフェースどおりにスタブを作る。既存の関数を変える場合は既存の実装を残す。
5. test-items.md の機械検証の項目ごとにテストを書く。説明に `DES-xxx #n` を書く（TEST-12）。既存のテストは「既存の振る舞いへの影響」で決めたものだけを変更・削除する。

## Red
6. tech.md の「テスト（1ファイル指定）」で対象の DES のテストファイルだけを実行し、TEST-03（既存コードを変える DES は TEST-08）を満たすか確かめる。満たさなければ 5 に戻る。件数を `task.sh log` で書く。

## テストのレビューと凍結
7. `/review-loop test <テストファイル>` でレビューする。テストを直したら 6 からやり直す。
8. 合格したらテストファイルと TASK をコミットする（例: `test(DES-xxx): <要約>`）。実装のファイル（スタブを含む）は含めない。
9. `task.sh freeze` で凍結し、`task.sh log` で凍結コミットのハッシュを書く（コミットは 11 で行う）。以後、hook がテストの編集を止める。

## Green と Refactor
10. 対象の DES のテストファイルが成功するように実装する。実行するのは「テスト（1ファイル指定）」だけにする（TEST-06）。テストが誤っていると判断したら止めて報告する（TEST-05）。
11. 対象のテストファイル、リント、フォーマット、ビルドをすべて成功させ、実装と TASK（凍結の記録と Green のログ）をコミットする。
12. 振る舞いを変えずに整理し、変更のたびに対象のテストファイルを実行する。整理を終えたら「テスト（全件）」を1回だけ実行し、既存のテストを含めて成功させてからコミットする（TEST-07・08）。

## コードのレビュー
13. `/review-loop code` で、凍結コミット（削除だけの DES は 3 のコミット）からの差分をレビューする。

## 完了
14. TASK を `done` にし、レビューの記録と合わせてコミットする。`bash .claude/scripts/branch.sh pr` でプッシュし、test-items.md の対象 DES の人間確認の項目を PR 本文の「人間確認の項目」に足す（TEST-13）。この DES で作業ブランチの範囲（GIT-03 の表）の実装がすべて終わらないなら、確認は求めずに次の DES の `/implement-tdd` に進む。
15. 範囲の最後の DES なら、PR 本文を最新にして `bash .claude/scripts/branch.sh ready` を実行する（CI を待つのはこの1回）。
16. 範囲の全 DES の人間確認の項目を、1つの承認パケット（GIT-30）で示して確認を求める。差分リンクは PR のリンクと、DES ごとのテストの `branch.sh link --commit <凍結コミット>` にする。返答の後に PR へのコメントも読む（GIT-32）。
17. 確認を得たら、結果を範囲の最後の TASK に `task.sh log` で書いてコミット・プッシュし（TASK だけの変更なので CI は開発コマンドを飛ばす。GIT-24）、`bash .claude/scripts/branch.sh merge` でマージする。直す点があれば、該当する DES の TASK を `in-progress` に戻して 10 からやり直す（テストの誤りは TEST-05、設計の誤りは WF-13）。
18. `bash .claude/scripts/progress.sh` の「プロジェクト全体の点検の材料」が WF-25 に当たれば、`/refactor` の実行を1行で提案する。
