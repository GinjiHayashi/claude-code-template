---
status: final
updated: 2026-10-14
related: [REQ-001, REQ-004]
---
# DES-001 幹事負担の計算とプロジェクトの土台

> 実装レベルの粒度で書く。コード本体は書かない。必須項目の定義の正本は guidelines/planning.md。

## 対応要件
> 満たす REQ の ID と、その要件のどの受け入れ基準を担うか。

- REQ-001: 受け入れ基準6（人数 1〜100 × 金額8種での検算式・100の倍数・不等式）。受け入れ基準1・3〜5の数値（表示を除く計算結果）も、この計算が担う
- REQ-004: 受け入れ基準1（計算部分のモジュール `src/warikan/calc.py` の行カバレッジ 90% 以上）

## 概要
> この設計単位で何を作るか。1〜3文。

プロジェクトの土台（pyproject.toml、パッケージ）を作り、入出力を持たない計算モジュールに「幹事負担」の計算を実装する。許容範囲の定数と入力値の検証もこのモジュールに置き、ほかの要件の設計から再利用する。

## 配置
> 作成・変更するファイルのパス。

| パス | 種類 | 内容 |
|---|---|---|
| `pyproject.toml` | 新規 | プロジェクト設定 |
| `src/warikan/__init__.py` | 新規 | パッケージの目印（中身は空） |
| `src/warikan/calc.py` | 新規 | 計算モジュール |
| `tests/test_calc.py` | 新規 | 計算モジュールのテスト |
| `uv.lock` | 生成 | `uv sync` が生成する。手で書かない |

## インタフェース
> 公開する関数・モジュール・エンドポイントごとに、入力、出力、エラー（どの条件で何を返すか）。

### 定数（`warikan.calc`）

| 名前 | 値 | 意味 |
|---|---|---|
| `MIN_TOTAL` | 1 | 合計金額の下限 |
| `MAX_TOTAL` | 1000000 | 合計金額の上限 |
| `MIN_PEOPLE` | 1 | 人数の下限 |
| `MAX_PEOPLE` | 100 | 人数の上限 |
| `ROUNDING_UNIT` | 100 | 1人あたりの額をそろえる単位（円） |

### `split_organizer_pays(total: int, people: int) -> OrganizerPaysSplit`

- 入力: `total` 合計金額（円）、`people` 人数
- 出力: `OrganizerPaysSplit`（データ構造を参照）
- エラー（上から順に判定し、最初に当たったものを送出する）

| 条件 | 送出する例外 | メッセージ |
|---|---|---|
| `total` の型が `int` でない（`bool` も `int` でないとみなす） | `TypeError` | `合計金額は整数で指定する: <repr(total)>` |
| `people` の型が `int` でない（`bool` を含む） | `TypeError` | `人数は整数で指定する: <repr(people)>` |
| `total` が `MIN_TOTAL` 未満または `MAX_TOTAL` 超 | `ValueError` | `合計金額は 1〜1,000,000 の範囲で指定する: <total>` |
| `people` が `MIN_PEOPLE` 未満または `MAX_PEOPLE` 超 | `ValueError` | `人数は 1〜100 の範囲で指定する: <people>` |

メッセージ中の範囲の数値は、定数を3桁区切り（書式指定 `,`）で文字列にして組み立てる（直接書かない）。

## データ構造
> 扱うデータの形、型、制約。

`OrganizerPaysSplit`（`warikan.calc`、`dataclasses.dataclass(frozen=True)`）

| フィールド | 型 | 制約 |
|---|---|---|
| `per_person` | `int` | 0 以上、`ROUNDING_UNIT` の倍数 |
| `organizer_payment` | `int` | `per_person` 以上。`per_person × (people − 1) + organizer_payment = total` |

`pyproject.toml` の内容（項目と値だけを示す）

| 項目 | 値 |
|---|---|
| `[project]` | `name = "warikan"`、`version = "0.1.0"`、`requires-python = ">=3.12,<3.13"`、`dependencies = []` |
| `[build-system]` | uv の標準ビルドバックエンド `uv_build`（`>=0.12,<0.13`） |
| `[dependency-groups] dev` | `pytest>=8,<9`、`pytest-cov`、`ruff` |
| `[tool.pytest.ini_options]` | `testpaths = ["tests"]` |
| `[tool.ruff.lint]` | `extend-select = ["I"]` |

## 処理方針
> 処理の流れ、アルゴリズム、採用しなかった案があれば理由。

1. 入力値を検証する（エラーの表の順）。
2. `per_person = total // people // ROUNDING_UNIT * ROUNDING_UNIT` で、1人あたりの額を100円単位に切り捨てる。整数の切り捨て除算を2回続けても、`floor(total / (people × 100)) × 100` と同じ値になる。
3. `organizer_payment = total − per_person × (people − 1)` で幹事の支払額を求める。
4. `OrganizerPaysSplit` を返す。

- `float` は使わない（tech.md の制約）。
- REQ-004 の確認: Green の後、code-reviewer に依頼する前に、tech.md の「テスト（全件）」を実行し、`src/warikan/calc.py` の `Cover` が 90% 以上であることを確かめる（REV-14）。
- 許容範囲の検証は計算モジュールに1か所だけ置く。コマンドライン側（REQ-003 の設計）は、この例外を受けて利用者向けのエラーにする。

## テスト項目
> 3分類で書く。異常系・境界値・敵対的入力を必ず含める。詳細なルールの正本は guidelines/testing.md。

### 機械検証（テストコードで検証する）

対象はすべて `split_organizer_pays`。

1. 正常系: `(10000, 3)` → `per_person=3300, organizer_payment=3400`
2. 正常系（割り切れる）: `(9000, 3)` → `3000, 3000`
3. 正常系（1人あたり 0円）: `(250, 3)` → `0, 250`
4. 正常系（1人）: `(10050, 1)` → `10000, 10050`
5. 網羅: 人数 1〜100 のすべてと、合計金額 1、99、100、101、9999、10000、999999、1000000 のすべての組み合わせで、次の3つが成り立つ。(a) `per_person × (people − 1) + organizer_payment == total` (b) `per_person % 100 == 0` (c) `per_person × people ≤ total < (per_person + 100) × people`
6. 境界値（最小）: `(1, 1)` → `0, 1`
7. 境界値（最小の直後）: `(2, 1)` → `0, 2`、`(2, 2)` → `0, 2`、`(1, 2)` → `0, 1`
8. 境界値（最大）: `(1000000, 100)` → `10000, 10000`
9. 境界値（範囲外）: `total` が 0、1000001 のとき `ValueError`、メッセージに「合計金額」と「1〜1,000,000」を含む
10. 境界値（範囲外）: `people` が 0、101 のとき `ValueError`、メッセージに「人数」と「1〜100」を含む
11. 異常系（負の値）: `total=-1`、`people=-1` のとき、それぞれ9・10と同じ `ValueError`
12. 敵対的入力（想定外の型）: `total` に `"10000"`、`None`、`1.5`、`True` を渡すと `TypeError`、メッセージに「合計金額」と「整数」を含む
13. 敵対的入力（想定外の型）: `people` に `"3"`、`None`、`3.0`、`True` を渡すと `TypeError`、メッセージに「人数」と「整数」を含む
14. 敵対的入力（極端に大きい値）: `total=10**100` のとき `ValueError`、メッセージに「合計金額」を含む
15. 異常系（判定の順序）: `total` と `people` がどちらも範囲外（`(0, 0)`）のとき、メッセージに「合計金額」を含む

該当しない種類: 「空」「特殊文字・制御文字」「注入を狙った文字列」「重複」は、引数が整数2つだけで文字列や集合を受け取らないため該当しない（文字列は12・13で型違いとして扱う）。

### AI レビュー（テストコードでは検証できないもの）

- `calc.py` が `float`、`/`（真の除算）、`round` を使っていない
- `calc.py` が`sys`・`argparse` を import せず、`print`・`input` を呼んでいない（architecture.md の依存の向き）
- 範囲の数値が定数以外の場所に直接書かれていない（CODE-16）

### 人間確認

- 該当なし（画面表示を持たないため。表示の確認は DES-002 で行う）

## 判断
> Claude が推奨案で決めた判断（PLAN-18）。人間は承認時にここを確認する。判断がなければ「（なし）」。

| 判断 | 選択肢 | 採用 | 理由 |
|---|---|---|---|
| 設計の分割 | (a) REQ-001 を1つの DES にする (b) 計算と CLI に分ける | (b) | 作成するファイルが7つ以上になり、PLAN-14 の上限（5つ）を超えるため。計算と入出力の分離（tech.md）とも境界が一致する |
| `.gitignore` の置き場所 | (a) DES-001 (b) DES-002 | (b) | DES-001 は生成物の `uv.lock` を含めて5ファイルになり、PLAN-14 の上限内に収めるため。DES-001 の実装中に出る生成物はコミットの対象に含めない |
| 許容範囲の検証の置き場所 | (a) 計算モジュール (b) CLI だけ (c) 両方 | (a) | 範囲を1か所で定義でき（DOC-01、CODE-12）、計算を直接呼んでも不正な値で誤った結果を返さない。CLI はこの例外を利用者向けに変換する |
| エラーメッセージの言語 | (a) 日本語 (b) 英語 | (a) | REQ-003 が利用者向けに求める文字列（「合計金額」「1〜1,000,000」など）をそのまま満たし、CLI 側で書き直さずに済むため |
| 結果の型 | (a) frozen dataclass (b) タプル (c) dict | (a) | フィールド名で意味が分かり、変更できない。標準ライブラリだけで書ける |
| `bool` の扱い | (a) 型エラーにする (b) `int` として受け付ける | (a) | `True` が 1人として計算されるのは呼び出し側の誤りであり、黙って計算しないため |
| REQ-004 をこの DES に含める | (a) 含める (b) 別の DES にする | (a) | 非機能要件は最初の設計に含める（WF-02）。カバレッジは計算モジュールのテストで決まるため |
| ビルドバックエンド | (a) `uv_build` (b) `hatchling` | (a) | tech.md のパッケージ管理が uv であり、追加のツールを増やさないため |

## 未決事項

（なし）
