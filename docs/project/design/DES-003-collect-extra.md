---
status: final
updated: 2026-10-14
related: [REQ-002, DES-001, DES-002]
---
# DES-003 多めに集める

> 実装レベルの粒度で書く。コード本体は書かない。必須項目の定義の正本は guidelines/planning.md。

## 対応要件
> 満たす REQ の ID と、その要件のどの受け入れ基準を担うか。

- REQ-002: 受け入れ基準1〜5のすべて（1〜3 の表示と終了コード、4 の網羅検算、5 の表示形式）

## 概要
> この設計単位で何を作るか。1〜3文。

計算モジュールに「多めに集める」の計算を追加し、コマンドラインで `--method collect-extra` を指定したときに、1人あたりの額と余りを表示する。

## 配置
> 作成・変更するファイルのパス。

| パス | 種類 | 内容 |
|---|---|---|
| `src/warikan/calc.py` | 変更 | `CollectExtraSplit` と `split_collect_extra` を追加する |
| `src/warikan/cli.py` | 変更 | `--method` の選択肢に `collect-extra` を追加し、方式で出力を分ける |
| `tests/test_calc.py` | 変更 | `split_collect_extra` のテストを追加する（既存のテストは変えない） |
| `tests/test_cli.py` | 変更 | `collect-extra` のテストを追加する（既存のテストは変えない） |

## インタフェース
> 公開する関数・モジュール・エンドポイントごとに、入力、出力、エラー（どの条件で何を返すか）。

### `split_collect_extra(total: int, people: int) -> CollectExtraSplit`（`warikan.calc`）

- 入力: `total` 合計金額（円）、`people` 人数
- 出力: `CollectExtraSplit`（データ構造を参照）
- エラー: DES-001 の `split_organizer_pays` のエラー表と同じ条件・順序・例外・メッセージとする

### コマンドライン（DES-002 からの変更）

```
python -m warikan <合計金額> <人数> [--method {organizer-pays,collect-extra}]
```

- `--method collect-extra` のときの出力（標準出力、2行）:

```
1人あたり <1人あたりの額>円
余り <余り>円
```

金額の書式は DES-002 と同じ（3桁ごとのカンマ区切り）。終了コードは 0。`--method` を省略したとき、または `organizer-pays` のときの出力は DES-002 のまま変えない。

### `main(argv: list[str] | None = None) -> int`（`warikan.cli`）

- 入力・出力・エラーは DES-002 と同じ。上記の方式による出力の分岐だけを加える

## データ構造
> 扱うデータの形、型、制約。

`CollectExtraSplit`（`warikan.calc`、`dataclasses.dataclass(frozen=True)`）

| フィールド | 型 | 制約 |
|---|---|---|
| `per_person` | `int` | `ROUNDING_UNIT` 以上、`ROUNDING_UNIT` の倍数 |
| `surplus` | `int` | 0 以上 `ROUNDING_UNIT × people` 未満。`per_person × people − surplus = total` |

方式の値は `organizer-pays` と `collect-extra` の2つ（architecture.md の命名表）。

## 処理方針
> 処理の流れ、アルゴリズム、採用しなかった案があれば理由。

### 計算（`split_collect_extra`）

1. 入力値を検証する。検証は `split_organizer_pays` と同じ処理を共通の内部関数にまとめて呼ぶ（CODE-12）。
2. `per_person = -(-total // (people × ROUNDING_UNIT)) × ROUNDING_UNIT` で、1人あたりの額を100円単位に切り上げる（tech.md の制約にある整数演算での切り上げ）。
3. `surplus = per_person × people − total` で余りを求める。
4. `CollectExtraSplit` を返す。

### コマンドライン

1. `--method` の `choices` に `collect-extra` を加える。既定値は `organizer-pays` のまま。
2. `args.method` が `collect-extra` なら `split_collect_extra` を呼び、「1人あたり」と「余り」の2行を出す。それ以外（`organizer-pays`）なら DES-002 の処理のまま。
3. 金額の整形は DES-002 の整形関数を共通で使う。

- 採用しなかった案: 方式を引数で渡す1つの関数。理由は判断の表「計算関数の形」を参照。

## テスト項目
> 3分類で書く。異常系・境界値・敵対的入力を必ず含める。詳細なルールの正本は guidelines/testing.md。

### 機械検証（テストコードで検証する）

1〜11 の対象は `split_collect_extra`。

1. 正常系: `(10000, 3)` → `per_person=3400, surplus=200`
2. 正常系（割り切れる）: `(9000, 3)` → `3000, 0`
3. 正常系（1人）: `(10050, 1)` → `10100, 50`
4. 網羅: 人数 1〜100 のすべてと、合計金額 1、99、100、101、9999、10000、999999、1000000 のすべての組み合わせで、次の3つが成り立つ。(a) `per_person × people − surplus == total` (b) `per_person % 100 == 0` (c) `(per_person − 100) × people < total ≤ per_person × people`
5. 境界値（最小）: `(1, 1)` → `100, 99`
6. 境界値（最小の直後）: `(2, 1)` → `100, 98`、`(1, 2)` → `100, 199`
7. 境界値（最大とその直前）: `(1000000, 100)` → `10000, 0`、`(999999, 100)` → `10000, 1`
8. 境界値（範囲外）: `total` が 0、1000001 のとき `ValueError`、メッセージに「合計金額」と「1〜1,000,000」を含む。`people` が 0、101 のとき `ValueError`、メッセージに「人数」と「1〜100」を含む
9. 異常系（負の値）: `total=-1` のとき8の合計金額と同じ `ValueError`、`people=-1` のとき8の人数と同じ `ValueError`
10. 敵対的入力（想定外の型・極端な値）: `total` に `"10000"`、`None`、`1.5`、`True` を渡すと `TypeError`（メッセージに「合計金額」と「整数」）。`people` に `"3"`、`None`、`3.0`、`True` を渡すと `TypeError`（メッセージに「人数」と「整数」）。`total=10**100` のとき `ValueError`（メッセージに「合計金額」）
11. 異常系（判定の順序）: `(0, 0)` のとき `ValueError`、メッセージに「合計金額」を含み「人数」を含まない

12〜15 は `main` を呼び、戻り値と標準出力の全文（`capsys`）を確かめる。

12. 正常系: `["10000", "3", "--method", "collect-extra"]` → 0、`1人あたり 3,400円\n余り 200円\n`
13. 正常系（割り切れる・1人）: `["9000", "3", "--method", "collect-extra"]` → 0、`1人あたり 3,000円\n余り 0円\n`。`["10050", "1", "--method", "collect-extra"]` → 0、`1人あたり 10,100円\n余り 50円\n`
14. 境界値（表示形式）: `["1000000", "1", "--method", "collect-extra"]` → 0、`1人あたり 1,000,000円\n余り 0円\n`。`["1", "1", "--method", "collect-extra"]` → 0、`1人あたり 100円\n余り 99円\n`。`["1000000", "100", "--method", "collect-extra"]` → 0、`1人あたり 10,000円\n余り 0円\n`
15. 正常系（オプションの位置）: `["--method", "collect-extra", "10000", "3"]` → 0、`1人あたり 3,400円\n余り 200円\n`

該当しない種類:
- 計算の「空」「特殊文字・制御文字」「注入を狙った文字列」「重複」は、DES-001 と同じ理由（引数が整数2つだけ）で該当しない。
- コマンドラインの異常系と敵対的入力（未知の方式、不正な文字列、範囲外）は、REQ-003 の設計でテストする。
- 方式の省略時と `organizer-pays` の出力は、DES-002 の既存テスト（変更しない）で確かめる。

### AI レビュー（テストコードでは検証できないもの）

- `calc.py` の入力検証が、2つの計算関数で重複せず1か所にまとまっている（CODE-12）
- 切り上げに `float`、`/`、`math.ceil` を使っていない（tech.md の制約）
- `cli.py` の金額整形が方式ごとに重複していない（CODE-12）

### 人間確認

- ターミナルで `uv run python -m warikan 10000 3 --method collect-extra` を実行し、2行の表示だけを見て、参加者に伝える額（1人あたり）と余りを取り違えずに読み上げられる

## 判断
> Claude が推奨案で決めた判断（PLAN-18）。人間は承認時にここを確認する。判断がなければ「（なし）」。

| 判断 | 選択肢 | 採用 | 理由 |
|---|---|---|---|
| 設計の分割 | (a) DES-003 の1つ (b) 計算と CLI に分ける | (a) | 変更するファイルが4つで PLAN-14 の上限内であり、1回の TDD サイクルで実装できるため |
| 計算関数の形 | (a) 方式ごとに別の関数 (b) 方式を引数で渡す1つの関数 | (a) | 方式ごとに結果のフィールドが違い、戻り値の型を1つに決められないため。既存の `split_organizer_pays` も変えずに済む |
| 入力検証 | (a) 既存の検証を内部関数にまとめて共用 (b) 関数ごとに書く | (a) | 同じ規則を2か所に書かない（CODE-12）。許容範囲の定義も1か所のまま保てる |
| 切り上げの方法 | (a) 負の数の切り捨て除算 `-(-a // b)` (b) `math.ceil(a / b)` | (a) | tech.md の制約（`float` を使わず整数演算で切り上げる）に従うため |
| テストの置き場所 | (a) 既存の `test_calc.py`・`test_cli.py` に追加 (b) 新しいテストファイル | (a) | architecture.md の命名規則（モジュールごとに1つのテストファイル）に従う。DES-001・DES-002 の TASK は完了しており、凍結は解除されている（TEST-04） |

## 未決事項

（なし）
