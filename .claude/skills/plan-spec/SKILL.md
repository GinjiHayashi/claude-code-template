---
name: plan-spec
description: 要件（REQ）を定義するとき、または要件の設計（DES）を作るときに使う。新機能の追加や仕様の検討を頼まれたときも使う。引数なしで要件定義、REQ の ID でその要件の設計を行う。
argument-hint: "[REQ-ID]"
---
# 計画（要件・設計）

引数: `$ARGUMENTS`（空なら要件定義、REQ の ID なら設計）

## 準備
1. `docs/guidelines/planning.md`、`docs/guidelines/documentation.md`、`docs/guidelines/workflow.md` を読む。人間の作業は承認と確認だけにする（WF-12、WF-13）。
2. `docs/project/overview.md`、`docs/project/tech.md`、`docs/project/glossary.md` を読む。
3. TASK ファイルを作り（要件定義なら「要件定義」、設計なら「REQ-xxx の設計」）、`status: in-progress` にする（WF-08）。

## 要件定義（引数なし）
4. overview.md の目的・スコープ・成功基準から要件を洗い出し、推奨案で内容を決める（PLAN-18）。PLAN-19 に当たる判断だけ、1問ずつ質問する（PLAN-01）。
5. 要件ごとに `docs/guidelines/templates/requirement.md` から `docs/project/requirements/REQ-xxx-<名前>.md` を作る（PLAN-08〜10）。
6. 全要件ができたら `/review-loop` Skill を使い、種別 `plan`、対象を全 REQ としてレビューする。
7. 合格したら、要件一覧と各 REQ の「判断」セクションをユーザーに示して承認を求める（WF-05）。承認後、各 REQ を `status: final` にする。

## 設計（引数が REQ の ID）
8. 対象の REQ と `docs/project/architecture.md` を読む。architecture.md がなければテンプレートから作り、最初の設計で決める（WF-02）。
9. 既存コードの事実は Explore サブエージェントで調べる（PLAN-02）。
10. 設計の判断（配置、インタフェース、データ構造、処理方針）を推奨案で決める（PLAN-18）。PLAN-19 に当たる判断だけ、1問ずつ質問する（PLAN-01）。
11. `docs/guidelines/templates/design.md` から DES を作り、PLAN-11 の全項目とテスト項目（TEST-08、TEST-11）を書く。ファイルが5つを超える場合は分割する（PLAN-14）。
12. 対象 REQ の受け入れ基準がすべて DES に割り当てられたか確認する（PLAN-13）。
13. `/review-loop` Skill を使い、種別 `plan`、対象を作成した DES としてレビューする。
14. 合格したら、設計と各 DES の「判断」セクションをユーザーに示して承認を求める（WF-06）。承認後、各 DES を `status: final` にし、DES ごとに実装用の TASK（`status: todo`）を作る。

## 共通
- 判断が DOC-15 を満たしたら ADR を、用語が決まったら glossary.md を更新する（PLAN-16、PLAN-17）。
- 設計中に要件の誤りを見つけたら止めて報告する（WF-11）。
- 完了時に TASK を `done` にし、作業ログを書く。次に進む Skill（設計なら `/plan-spec REQ-xxx`、実装なら `/implement-tdd DES-xxx`）を伝える。
