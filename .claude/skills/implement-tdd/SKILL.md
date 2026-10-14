---
name: implement-tdd
description: 承認済みの設計（DES）を実装するときに使う。テストとスタブ作成、Red の確認、テストのレビュー、Green、Refactor、コードのレビューまでを TDD で行う。
argument-hint: "<DES-ID>"
---
# 実装（TDD）

対象: `$ARGUMENTS`（DES の ID）

## 準備
1. この会話でまだ読んでいない（圧縮などで内容が残っていない場合を含む）ときだけ、`docs/guidelines/testing.md` と `docs/guidelines/coding.md` を読む。
2. 対象の DES、対応する REQ、`docs/project/test-items.md` の対象 DES の見出し、`docs/project/architecture.md`、`docs/project/tech.md` を読む（読み済みの扱いは 1 と同じ）。
3. 対象 DES の TASK を `task.sh status <TASK-ID> in-progress` で進行中にする。
   - 対象 DES が振る舞いを削除するだけの場合（TEST-23）は、4〜9 を省く。「既存の振る舞いへの影響」に挙げたテストとコードを削除し、11 の検証を成功させてから 13 に進む。完了時に PLAN-24 のとおり DES を `retired` にし、test-items.md の見出しに `（retired）` を付ける。

## テストとスタブ（TEST-01 の (1)）
4. DES のインタフェースどおりにスタブを作る（TEST-02）。既存の関数を変更する場合は、既存の実装を残す。
5. test-items.md の機械検証の項目ごとにテストを書く（TEST-08、TEST-11）。テスト名は振る舞いを表し、テストの説明に `DES-xxx #n` を書く（TEST-09）。関数の説明とコメントは CODE-22・27・28 に従う。既存のテストは、DES の「既存の振る舞いへの影響」で変わる・なくなると決めたものだけを変更・削除する（TEST-22）。禁止事項（TEST-12〜19）に当たる書き方をしない。

## Red（TEST-01 の (2)）
6. tech.md の「テスト（全件）」のコマンドを実行する。
7. 全件がアサーション失敗か未実装エラーで失敗したか確認する（TEST-03）。既存のファイルを変更する DES では、新しいテストは全件失敗し、既存のテストと「保持」の項目のテストは成功していることを確認する（TEST-21）。満たさなければ 5 に戻る。結果の件数を作業ログに書く。

## テストのレビュー（TEST-01 の (3)）
8. `/review-loop` Skill を使い、種別 `test`、対象をテストファイルとしてレビューする（差分ファイルは /review-loop が作る）。テストを直したら 6 からやり直す。
9. 合格したらテストファイルだけをコミットする（例: `test: DES-xxx のテストを追加`）。`task.sh freeze` で TASK の `frozen_tests` にテストファイルのパスを書き、`task.sh log` で作業ログに凍結コミットのハッシュを書く。この時点でテストは凍結となり、hook が編集を止める（TEST-04）。

## Green（TEST-01 の (4)）
10. 全テストが成功するように実装する。テストファイルは変更しない（TEST-04）。テストの誤りに気づいたら止めて報告する（TEST-05）。
11. tech.md のテスト、リント、フォーマット、ビルドのコマンドを実行し、すべて成功させる（TEST-06、REV-14）。

## Refactor（TEST-01 の (5)）
12. CODE ルールに沿って整理する。変更のたびに全テストを実行する（TEST-07）。

## コードのレビュー（TEST-01 の (6)）
13. `/review-loop` Skill を使い、種別 `code`、対象を凍結コミット以降の git diff（テストファイルを含む）としてレビューする。

## 完了
14. test-items.md の対象 DES の人間確認の項目を一覧にし、ユーザーに確認を依頼する（TEST-10）。
15. TASK を `done` にし、作業ログを書く。設計の誤りを見つけていた場合は WF-10 に従う。
16. `bash .claude/scripts/progress.sh` の「プロジェクト全体の点検の材料」で WF-24 に当たるか確かめ、当たれば `/refactor` の実行を1行で提案する。
