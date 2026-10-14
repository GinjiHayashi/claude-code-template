---
name: plan-spec
description: 要件（REQ）を定義するとき、または要件の設計（DES）を作るときに使う。新機能の追加や仕様の検討を頼まれたときも使う。引数なしで要件定義、REQ の ID でその要件の設計を行う。
argument-hint: "[REQ-ID]"
---
# 計画（要件・設計）

引数: `$ARGUMENTS`（空なら要件定義、REQ の ID なら設計）

## 準備
1. この会話でまだ読んでいない（圧縮などで内容が残っていない場合を含む）ときだけ、`docs/guidelines/planning.md`、`docs/guidelines/documentation.md`、`docs/guidelines/workflow.md` を読む。人間の作業は承認と確認だけにする（WF-12、WF-13）。
2. `docs/project/overview.md`、`docs/project/tech.md`、`docs/project/glossary.md` を読む。
3. `task.sh new` で TASK ファイルを作り（要件定義なら「要件定義」、設計なら「REQ-xxx の設計」）、`task.sh status` で `in-progress` にする（WF-08）。

## 要件定義（引数なし）
4. overview.md の目的・スコープ・成功基準から要件を洗い出し、推奨案で内容を決める（PLAN-18）。PLAN-19 に当たる判断だけ、1問ずつ質問する（PLAN-01）。
5. 要件ごとに `docs/guidelines/templates/requirement.md` から `docs/project/requirements/REQ-xxx-<名前>.md` を作る（PLAN-08〜10）。`<名前>` は英語のケバブケースで、用語は glossary.md の「コード上の名前」を使う（DOC-04）。glossary.md にない用語は先に登録する（PLAN-17）。
6. 要件の実装順を決め、順序と理由を TASK の「完了したこと」に書く（WF-17）。
7. 全要件ができたら `/review-loop` Skill を使い、種別 `plan`、対象を全 REQ としてレビューする。
8. 合格したら、要件一覧、実装順、各 REQ の「判断」セクションをユーザーに示して承認を求める（WF-05）。承認後、各 REQ を `status: final` にする。

## 設計（引数が REQ の ID）
9. 対象の REQ と `docs/project/architecture.md` を読む。architecture.md がなければテンプレートから作り、最初の設計で決める（WF-02）。
10. 既存コードの事実は Explore サブエージェントで調べる（PLAN-02）。
11. 設計の判断（配置、インタフェース、データ構造、処理方針）を推奨案で決める（PLAN-18）。PLAN-19 に当たる判断だけ、1問ずつ質問する（PLAN-01）。
12. `docs/guidelines/templates/design.md` から DES を作り、PLAN-11 の全項目を書く。既存のファイルを変更する場合は「既存の振る舞いへの影響」を書く（PLAN-20）。ファイルが5つを超える場合は分割する（数えないファイルは PLAN-14）。
13. `docs/project/test-items.md`（なければ `docs/guidelines/templates/test-items.md` から作る）に、DES ごとの見出しを作ってテスト項目を書く（TEST-08、TEST-11）。既存の振る舞いを保つ確認の項目には「保持」の印を付ける（TEST-21）。
14. 対象 REQ の受け入れ基準がすべて DES に割り当てられ、test-items.md のどれかの項目で検証されるか確認する（PLAN-13）。
15. `/review-loop` Skill を使い、種別 `plan`、対象を作成した DES としてレビューする。
16. 合格したら、設計と各 DES の「判断」セクションをユーザーに示して承認を求める（WF-06）。承認後、各 DES を `status: final` にし、DES ごとに実装用の TASK（`status: todo`）を作る。DES が1つだけなら、この TASK を実装に引き継いでよい（WF-08）。

## 共通
- 判断が DOC-15 を満たしたら ADR を、用語が決まったら glossary.md を更新する（PLAN-16、PLAN-17）。
- 設計中に要件の誤りを見つけたら止めて報告する（WF-11）。
- 完了時に TASK を `done` にし、作業ログを書く。次に進む Skill（設計なら `/plan-spec REQ-xxx`、実装なら `/implement-tdd DES-xxx`）を伝える。
