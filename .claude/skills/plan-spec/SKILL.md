---
name: plan-spec
description: 要件（REQ）を定義するとき、要件の設計（DES）を作るとき、開発開始の後に機能の追加・仕様の変更・機能の削除を計画するときに使う。新機能の追加や仕様の検討を頼まれたときも使う。引数なしで最初の要件定義、REQ の ID でその要件の設計、`change <変更内容>` で変更要求の計画を行う。
argument-hint: "[REQ-ID | change <変更内容>]"
---
# 計画（要件・設計・変更要求）

引数: `$ARGUMENTS`（空なら要件定義、REQ の ID なら設計、`change` で始まれば変更要求の計画）。完了条件は WF-06・07・21。

## 準備
1. 未読なら（圧縮で内容が消えた場合も）`docs/guidelines/planning.md`、`docs/guidelines/documentation.md`、`docs/guidelines/workflow.md`、`docs/guidelines/git.md` を読む。判断は推奨案で決め、質問は PLAN-06 に当たるものだけにする（PLAN-05・06）。質問は一覧を示してから1問ずつ行い、回答ごとに TASK に記録する（PLAN-07・08）。
2. `docs/project/` の overview.md、tech.md、glossary.md を読む。
3. 引数が空でも REQ がすでにあれば、ユーザーの依頼を変更内容として変更要求の計画（9〜14）に進む。
4. `bash .claude/scripts/task.sh begin --next '<次の一手>' <ブランチ名> <ファイル名> <タスク名> [関連ID]` で作業ブランチと TASK を作る。

   | 引数 | ブランチ名 | タスク名 | 次の一手 |
   |---|---|---|---|
   | 空 | `feature/setup` | 要件定義 | `/plan-spec` の手順 5: 要件を洗い出す |
   | `change` | `feature/change-<ファイル名>` | 変更要求: <変更内容の要約> | `/plan-spec change` の手順 9: 影響一覧を作る |
   | REQ の ID | `feature/REQ-xxx-<REQ のファイル名の名前部分>`。変更のブランチにいるなら `-`（切り替えない） | REQ-xxx の設計（関連ID に REQ） | `/plan-spec REQ-xxx` の手順 15: REQ と architecture.md を読む |

## 要件定義（引数なし）
5. overview.md の目的・スコープ・成功基準から要件を洗い出し、要件ごとに `templates/requirement.md` から `docs/project/requirements/REQ-xxx-<名前>.md` を作る（PLAN-13〜15）。`<名前>` は glossary.md の「コード上の名前」を使い、ない用語は先に登録する。
6. 要件の実装順を決め、順序と理由を TASK の「完了したこと」に書く（WF-03）。
7. `/review-loop plan <全 REQ>` でレビューし、合格したらコミットする。
8. PR 本文を最新にして `bash .claude/scripts/branch.sh ready` を実行し、要件一覧・実装順・各 REQ の「判断」を承認パケット（GIT-30）で示して承認を求める。承認後、各 REQ を `final`、TASK を `done` にしてコミットし、`bash .claude/scripts/branch.sh merge` でマージする。

## 変更要求の計画（引数が `change <変更内容>`）
9. 影響一覧を作り、TASK の「完了したこと」に書く（PLAN-25）。事実は Grep と Explore サブエージェントで調べる。
10. 目的・スコープ・成功基準が変わる場合は、overview.md の改訂点をユーザーに質問して決め、改訂する。非スコープの機能の REQ は、この改訂が終わるまで作らない。
11. 新しい要件は 5 と同じく作る。既存 REQ の受け入れ基準の変更と機能の削除は PLAN-24 で REQ を改訂する。影響一覧の REQ・DES のそれぞれに「追加」「改訂」「削除」「影響なし（理由）」を書く。
12. 変更分の実装順を決め、順序と理由を TASK の「完了したこと」に書く。
13. `/review-loop plan` で、追加・改訂した REQ、改訂した overview.md、影響一覧を書いた TASK をレビューし、合格したらコミットする。
14. `bash .claude/scripts/branch.sh pr` でプッシュし、影響一覧・実装順・各 REQ の「判断」・overview.md の改訂点を承認パケットで示して承認を求める。承認後、追加・改訂した資料を `final` にしてコミット・プッシュする。PR は変更分の実装がすべて終わるまでマージしない。続けて、実装順に `/plan-spec REQ-xxx` で設計に進むと伝える。

## 設計（引数が REQ の ID）
15. 対象の REQ と `docs/project/architecture.md` を読む（なければテンプレートから作り、この設計で決める。WF-02）。architecture.md を変える場合は PLAN-23 に従う。既存コードの事実は Explore サブエージェントで調べる。
16. 既存の振る舞いを変える・なくす場合は、それを担う既存 DES を改訂して `draft` に戻す（PLAN-22）。それ以外は `templates/design.md` から DES を作る。どちらも PLAN-16・19・21 を満たす。
17. `docs/project/test-items.md`（なければテンプレートから作る）に DES ごとの見出しとテスト項目を書く（TEST-11・14。既存の振る舞いを保つ確認には「保持」）。対象 REQ の受け入れ基準がすべて割り当てられたか確かめる（PLAN-18）。
18. `/review-loop plan` で、作成・改訂した DES（architecture.md を変えたらそれも）をレビューし、合格したらコミットする。
19. `bash .claude/scripts/branch.sh pr` でプッシュし、設計と各 DES の「判断」を承認パケットで示して承認を求める。承認後、各 DES を `final` にし、DES ごとに実装用の TASK を `task.sh new`（`status: todo`、関連ID に DES）で作る。PR は実装が終わるまでマージしない。

## 共通
- 返答を受けたら PR へのコメントも読む（GIT-32）。設計中に要件の誤りを見つけたら止めて報告する（WF-14）。
- 完了時に TASK を `done` にしてコミット・プッシュし、次に進む Skill（`/plan-spec REQ-xxx` か `/implement-tdd DES-xxx`）を伝える。
