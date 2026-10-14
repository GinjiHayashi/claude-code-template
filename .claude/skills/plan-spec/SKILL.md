---
name: plan-spec
description: 要件（REQ）を定義するとき、要件の設計（DES）を作るとき、開発開始の後に機能の追加・仕様の変更・機能の削除を計画するときに使う。新機能の追加や仕様の検討を頼まれたときも使う。引数なしで最初の要件定義、REQ の ID でその要件の設計、`change <変更内容>` で変更要求の計画を行う。
argument-hint: "[REQ-ID | change <変更内容>]"
---
# 計画（要件・設計・変更要求）

引数: `$ARGUMENTS`（空なら要件定義、REQ の ID なら設計、`change` で始まれば変更要求の計画）

## 準備
1. この会話でまだ読んでいない（圧縮などで内容が残っていない場合を含む）ときだけ、`docs/guidelines/planning.md`、`docs/guidelines/documentation.md`、`docs/guidelines/workflow.md` を読む。人間の作業は承認と確認だけにする（WF-12、WF-13）。
2. `docs/project/overview.md`、`docs/project/tech.md`、`docs/project/glossary.md` を読む。
3. 引数が空で、`docs/project/requirements/` に REQ がすでにある場合は、最初の要件定義は終わっている。ユーザーの依頼内容を変更内容として、変更要求の計画（手順 10〜17）に進む（WF-01）。
4. `task.sh new` で TASK ファイルを作り（設計なら関連 ID に対象の REQ を渡す。要件定義なら「要件定義」、設計なら「REQ-xxx の設計」、変更要求なら「変更要求: <変更内容の要約>」）、`task.sh status` で `in-progress` にする（WF-08）。

## 要件定義（引数なし）
5. overview.md の目的・スコープ・成功基準から要件を洗い出し、推奨案で内容を決める（PLAN-18）。PLAN-19 に当たる判断を先に洗い出し、質問の一覧を示してから（PLAN-26）、1問ずつ質問し、回答ごとに TASK に記録する（PLAN-01、PLAN-27）。
6. 要件ごとに `docs/guidelines/templates/requirement.md` から `docs/project/requirements/REQ-xxx-<名前>.md` を作る（PLAN-08〜10）。`<名前>` は英語のケバブケースで、用語は glossary.md の「コード上の名前」を使う（DOC-04）。glossary.md にない用語は先に登録する（PLAN-17）。
7. 要件の実装順を決め、順序と理由を TASK の「完了したこと」に書く（WF-17）。
8. 全要件ができたら `/review-loop` Skill を使い、種別 `plan`、対象を全 REQ としてレビューする。
9. 合格したら、要件一覧、実装順、各 REQ の「判断」セクションをユーザーに示して承認を求める（WF-05）。承認後、各 REQ を `status: final` にする。

## 変更要求の計画（引数が `change <変更内容>`）
10. 影響一覧を作り、TASK の「完了したこと」に書く（PLAN-25）。既存の REQ・DES・テスト・資料の事実は Grep と Explore サブエージェントで調べる（WF-03、PLAN-02）。
11. 変更で overview.md の目的・スコープ・成功基準が変わる場合は、改訂案を作り、改訂点を質問の一覧として示してから（PLAN-26）、1問ずつユーザーに質問して決め、回答ごとに TASK に記録する（PLAN-19 (1)、PLAN-01、PLAN-27）。決まったら overview.md を改訂する。非スコープにある機能の REQ は、この改訂が終わるまで作らない（PLAN-10）。
12. 新しい要件は手順 6 と同じく REQ を作る。既存 REQ の受け入れ基準の変更と機能の削除は PLAN-24 に従って REQ を改訂する。
13. 影響一覧の REQ・DES のそれぞれに「追加」「改訂」「削除」「影響なし（理由）」を書く（WF-19）。
14. 変更分の実装順を決め、順序と理由を TASK の「完了したこと」に書く（WF-17 を準用、WF-18）。
15. `/review-loop` Skill を使い、種別 `plan`、対象を追加・改訂した REQ、改訂した overview.md、影響一覧を書いた TASK としてレビューする（改訂した資料の差分も渡す。REV-12）。
16. 合格したら、影響一覧、実装順、各 REQ の「判断」セクション、overview.md の改訂点をユーザーに示して承認を求める（WF-19）。承認後、追加・改訂した REQ と overview.md を `status: final` にする。
17. 影響を受ける REQ ごとに、実装順に `/plan-spec REQ-xxx` で設計に進むと伝える。WF-08 の例外（REQ も DES も1つだけ）に当たる場合は、この TASK のまま設計・実装に進んでよい。

## 設計（引数が REQ の ID）
18. 対象の REQ と `docs/project/architecture.md` を読む。architecture.md がなければテンプレートから作り、最初の設計で決める（WF-02）。architecture.md を変える場合は PLAN-23 に従う。
19. 既存コードの事実は Explore サブエージェントで調べる（PLAN-02）。
20. 設計の判断（配置、インタフェース、データ構造、処理方針）を推奨案で決める（PLAN-18）。PLAN-19 に当たる判断を先に洗い出し、質問の一覧を示してから（PLAN-26）、1問ずつ質問し、回答ごとに TASK に記録する（PLAN-01、PLAN-27）。
21. 既存の振る舞いを変える・なくす場合は、その振る舞いを担う既存 DES を改訂し、`status: draft` に戻す（PLAN-22）。それ以外は `docs/guidelines/templates/design.md` から DES を作る。どちらも PLAN-11 の全項目を書く。既存のファイルを変更・削除する場合は「既存の振る舞いへの影響」を書く（PLAN-20）。ファイルが5つを超える場合は分割する（数えないファイルは PLAN-14）。
22. `docs/project/test-items.md`（なければ `docs/guidelines/templates/test-items.md` から作る）に、DES ごとの見出しを作ってテスト項目を書く（TEST-08、TEST-11）。既存の振る舞いを保つ確認の項目には「保持」の印を付ける（TEST-21）。改訂した DES の項目は PLAN-22 に従って更新する。
23. 対象 REQ の受け入れ基準（「（削除）」を除く）がすべて DES に割り当てられ、test-items.md のどれかの項目で検証されるか確認する（PLAN-13）。
24. `/review-loop` Skill を使い、種別 `plan`、対象を作成・改訂した DES（architecture.md を変えた場合はそれも）としてレビューする。
25. 合格したら、設計と各 DES の「判断」セクションをユーザーに示して承認を求める（WF-06）。承認後、各 DES を `status: final` にし、DES ごとに実装用の TASK（`status: todo`、`related` に DES の ID）を作る。DES が1つだけなら、この TASK を実装に引き継いでよい（WF-08）。その場合は `task.sh relate` でこの TASK の `related` に DES の ID を足す（WF-20）。

## 共通
- 判断が DOC-15 を満たしたら ADR を、用語が決まったら glossary.md を更新する（PLAN-16、PLAN-17）。
- 設計中に要件の誤りを見つけたら止めて報告する（WF-11）。
- 完了時に TASK を `done` にし、作業ログを書く。次に進む Skill（設計なら `/plan-spec REQ-xxx`、実装なら `/implement-tdd DES-xxx`）を伝える。DES が1つだけで実装まで終えた場合は、`bash .claude/scripts/progress.sh` の「プロジェクト全体の点検の材料」で WF-24 に当たるか確かめ、当たれば `/refactor` の実行を1行で提案する。
