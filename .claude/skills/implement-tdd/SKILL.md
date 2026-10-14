---
name: implement-tdd
description: 承認済みの設計（DES）を実装するときに使う。テストとスタブ作成、Red の確認、テストのレビュー、Green、Refactor、コードのレビューまでを TDD で行う。
argument-hint: "<DES-ID>"
---
# 実装（TDD）

対象: `$ARGUMENTS`（DES の ID）

## 準備
1. `docs/guidelines/testing.md` と `docs/guidelines/coding.md` を読む。
2. 対象の DES、対応する REQ、`docs/project/architecture.md`、`docs/project/tech.md` を読む。
3. 対象 DES の TASK を `status: in-progress` にする。

## テストとスタブ（TEST-01 の (1)）
4. DES のインタフェースどおりにスタブを作る（TEST-02）。
5. DES の機械検証の項目ごとにテストを書く（TEST-08、TEST-09、TEST-11）。禁止事項（TEST-12〜19）に当たる書き方をしない。

## Red（TEST-01 の (2)）
6. tech.md の「テスト（全件）」のコマンドを実行する。
7. 全件がアサーション失敗か未実装エラーで失敗したか確認する（TEST-03）。満たさなければ 5 に戻る。結果の件数を作業ログに書く。

## テストのレビュー（TEST-01 の (3)）
8. `/review-loop` Skill を使い、種別 `test`、対象をテストファイルとしてレビューする。テストを直したら 6 からやり直す。
9. 合格したらテストファイルだけをコミットする（例: `test: DES-xxx のテストを追加`）。TASK のフロントマター `frozen_tests` にテストファイルのパスを書き、作業ログに凍結コミットのハッシュを書く。この時点でテストは凍結となり、hook が編集を止める（TEST-04）。

## Green（TEST-01 の (4)）
10. 全テストが成功するように実装する。テストファイルは変更しない（TEST-04）。テストの誤りに気づいたら止めて報告する（TEST-05）。
11. tech.md のテスト、リント、フォーマット、ビルドのコマンドを実行し、すべて成功させる（TEST-06、REV-14）。

## Refactor（TEST-01 の (5)）
12. CODE ルールに沿って整理する。変更のたびに全テストを実行する（TEST-07）。

## コードのレビュー（TEST-01 の (6)）
13. `/review-loop` Skill を使い、種別 `code`、対象を凍結コミット以降の git diff（テストファイルを含む）としてレビューする。

## 完了
14. DES の人間確認の項目を一覧にし、ユーザーに確認を依頼する（TEST-10）。
15. TASK を `done` にし、作業ログを書く。設計の誤りを見つけていた場合は WF-10 に従う。
