---
status: final
updated: 2026-10-15
related: [REQ-001]
---
# DES-001 フレームの描画（ドーナツ）

> 実装レベルの粒度で書く。コード本体は書かない。必須項目の定義の正本は guidelines/planning.md。

## 対応要件

REQ-001 の受け入れ基準 1〜10 のすべて。

## 概要

描画計算（`spin.rendering`）と、ドーナツを持つ選べる図形の一覧（`spin.shapes`）を作る。表面の点の並びと回転角と画面の大きさから、陰影の付いた1フレームの文字列を返す純粋な関数を中心にする。

## 配置

作成するファイル（PLAN-14 で数える5つ）:
- `src/spin/__init__.py`（空）
- `src/spin/rendering.py`
- `src/spin/shapes.py`
- `tests/test_rendering.py`
- `tests/test_shapes.py`

数えないファイル（PLAN-14）:
- `pyproject.toml`: パッケージ名 `spin`、`requires-python = ">=3.12"`、実行時の依存なし。開発用の依存は tech.md の pytest・pytest-cov・Ruff（版の範囲も tech.md どおり）。ビルドバックエンドは `hatchling`。Ruff の有効にするルールと行の長さは tech.md「リンター」「フォーマッター」どおり。`[tool.pytest.ini_options]` の `testpaths = ["tests"]`。`[tool.hatch.build.targets.wheel]` の `packages = ["src/spin"]`。`[tool.ruff]` の `include = ["*.py", "*.pyi", "**/pyproject.toml"]`（tech.md の「フォーマット対象の拡張子」に合わせ、Markdown 内のコード例を整形の対象にしない。TASK-003 でユーザーが承認）。
- `uv.lock`（`uv sync` が生成する）。
- `.python-version`（`uv python pin 3.12` が生成する。tech.md の Python 3.12 に固定するため）。
- `.gitignore`: `.venv/`、`__pycache__/`、`.coverage`、`.pytest_cache/`、`.ruff_cache/` を足す（すでにある行は足さない）。

## インタフェース

### `spin.rendering`

| 名前 | 種類 | 入力 | 出力 | エラー |
|---|---|---|---|---|
| `Vector3` | 型の別名 | — | `tuple[float, float, float]` | — |
| `SurfacePoint` | 不変のデータクラス | `position: Vector3`、`normal: Vector3` | — | — |
| `Rotation` | 不変のデータクラス | `x_angle: float`（1つ目の軸 = x 軸の周り、ラジアン）、`z_angle: float`（2つ目の軸 = z 軸の周り、ラジアン） | — | — |
| `BOUNDING_RADIUS` | 定数 | — | `1.0`（すべての図形の外接球の半径） | — |
| `SHADE_CHARS` | 定数 | — | `".,-~:;=!*#$@"`（明るさの文字。左ほど暗い） | — |
| `LIGHT_DIRECTION` | 定数 | — | `(0.0, 1/√2, -1/√2)`（光源。表面から光が来る方への長さ 1 の向き。上かつ視点の側） | — |
| `rotate(point, rotation)` | 関数 | `SurfacePoint`、`Rotation` | 位置と面の向きの両方を回転した `SurfacePoint` | なし |
| `project(position, width, height)` | 関数 | 回転後の位置 `Vector3`（前提: 原点からの距離が `BOUNDING_RADIUS` 以下。それ以外の位置の結果は定めない）、画面の幅 `int`、高さ `int`（前提: 1 以上） | `(row, col, closeness)`。`row`・`col` は 0 始まりのマスの位置（`int`）、`closeness` は近さ（`float`、大きいほど視点に近い）。画面の外の位置もそのまま返す | なし |
| `shade(point)` | 関数 | 回転後の `SurfacePoint`（前提: 面の向きの長さが 1） | 明るさの文字1文字（`str`） | なし |
| `render_frame(points, rotation, width, height)` | 関数 | 表面の点の並び `Sequence[SurfacePoint]`、`Rotation`、幅 `int`、高さ `int` | フレーム。`height` 行を `"\n"` でつないだ文字列（末尾に改行なし）。各行はちょうど `width` 文字で、空白か明るさの文字だけを含む | `width < 1` または `height < 1` のとき `ValueError`（メッセージに引数名と値を含める） |

### `spin.shapes`

| 名前 | 種類 | 入力 | 出力 | エラー |
|---|---|---|---|---|
| `ShapeFactory` | 型の別名 | — | `Callable[[], tuple[SurfacePoint, ...]]` | — |
| `torus()` | 関数 | なし | ドーナツの表面の点のタプル | なし |
| `SHAPES` | 定数 | — | 図形の名前から `ShapeFactory` を引く読み取り専用の表（`types.MappingProxyType`）。この DES では `{"torus": torus}` だけ | — |

## データ構造

- 座標系: x は右、y は上、z は視点から離れる向き。図形の中心は原点。
- モジュール内だけで使う定数（`spin.rendering`。名前を `_` で始め、公開しない）:
  - `_VIEWPOINT_DISTANCE = 5.0`: 原点から視点までの距離。
  - `_VIEWPOINT = (0.0, 0.0, -_VIEWPOINT_DISTANCE)`: 視点の位置。
  - `_FILL_RATIO = 0.9`: 画面の縦横の半分のうち、外接球が占める割合。
  - `_CHAR_ASPECT = 2.0`: 横の倍率と縦の倍率の比（文字の縦長の補正）。
- モジュール内だけで使う定数（`spin.shapes`）: `_TUBE_STEPS = 60`、`_RING_STEPS = 200`、`_RING_RADIUS = 2/3`、`_TUBE_RADIUS = 1/3`。
- `SurfacePoint.normal` は長さ 1 とする。`position` の原点からの距離は `BOUNDING_RADIUS` 以下とする（`spin.shapes` が守る）。
- ドーナツ: 対称軸は z 軸（回転角 0 で穴が視点を向く）。中心円の半径 `2/3`、管の半径 `1/3`（外接球の半径 = 1）。管の周りの角を θ_i = 2π × i / 60（i = 0〜59）、中心円の周りの角を φ_j = 2π × j / 200（j = 0〜199）とし、すべての組で 12000 点を作る。θ = 0 を含むので、原点からの距離の最大値は、小数の誤差を除いて `BOUNDING_RADIUS` になる。位置は `((2/3 + cosθ/3)cosφ, (2/3 + cosθ/3)sinφ, sinθ/3)`、面の向きは `(cosθ cosφ, cosθ sinφ, sinθ)`。
- 奥行きバッファ: 高さ × 幅の `float` の表。初期値は 0（どの点の近さよりも小さい）。

## 処理方針

- **回転（`rotate`）**: 2つの角をそれぞれ 2π で割った余りにしてから使う。これにより、回転角 2π が回転角 0 と完全に同じ計算になり、小数の誤差でフレームがずれない（REQ-001 基準 3、TASK-002 の未解決事項の対応）。先に x 軸の周りに `x_angle`、次に z 軸の周りに `z_angle` 回す。x 軸の周り: `(x, y cos a − z sin a, y sin a + z cos a)`。z 軸の周り: `(x cos b − y sin b, x sin b + y cos b, z)`。位置と面の向きに同じ回転をかける。
- **投影（`project`）**: 透視投影とする。`closeness = 1 / (z + _VIEWPOINT_DISTANCE)`。
  - 倍率は次の順に決める。外接球の接線の傾き `t = BOUNDING_RADIUS / √(_VIEWPOINT_DISTANCE² − BOUNDING_RADIUS²)`。縦の半分の広さ `e = _FILL_RATIO × min(height / 2, width / 2 / _CHAR_ASPECT)`（幅の半分を横の倍率の比で割った値。`_CHAR_ASPECT = 2` で `width / 4`）。縦の倍率 `scale_y = e / t`、横の倍率 `scale_x = _CHAR_ASPECT × scale_y`（REQ-001 基準 6）。
  - マスの位置は `col = floor(width / 2 + scale_x × x × closeness)`、`row = floor(height / 2 − scale_y × y × closeness)`。
  - 外接球の中の点では `|x| × closeness ≤ t`、`|y| × closeness ≤ t` が成り立つ。そのため、横のずれは `0.9 × width / 2` 以下、縦のずれは `0.9 × height / 2` 以下になり、どの回転角・どの大きさでも画面の内側に収まる（REQ-001 基準 5）。小数の丸めで点の距離が `BOUNDING_RADIUS` をわずか（1e-9 未満の割合）に超えても、`_FILL_RATIO` による 10% の余裕で吸収されるので、`project` の前提の「`BOUNDING_RADIUS` 以下」はこの誤差を含めた意味とする。
- **明るさ（`shade`）**: 視点への向き `_VIEWPOINT − position` と面の向きの内積が負なら、面の向きを反転する（REQ-001 基準 8）。次に、そろえた面の向きと `LIGHT_DIRECTION` の内積 `L` を求める。`L ≤ 0` なら `.`、それ以外は `SHADE_CHARS[min(floor(L × 12), 11)]` とする（L = 1 で `@`、L = 0.5（60 度）で `SHADE_CHARS` の 0 始まりの添字 5 か 6（`;` か `=`）、REQ-001 基準 9）。
- **1フレーム（`render_frame`）**: 幅・高さを検証する。空白で埋めた高さ × 幅の表と奥行きバッファを用意する。各点を回転・投影し、画面の内側で、近さが奥行きバッファの値より真に大きいときだけ、奥行きバッファを更新して `shade` の文字を置く（REQ-001 基準 7）。近さが等しい点は先に処理した点を残すので、結果は点の並びの順で決まり、毎回同じになる。最後に行を `"\n"` でつなぐ。
- 表面の点は図形ごとに一度だけ作り、フレームごとに作り直さない（`render_frame` は点の並びを受け取る）。
- 採用しなかった案:
  - 平行投影は採らなかった。奥行きの感じが出ず、立体に見えにくいため。
  - `render_frame` が図形の名前を受け取る形は採らなかった。`spin.rendering` が `spin.shapes` に依存してしまい、architecture.md の依存の向きに反するため。

### 既存の振る舞いへの影響

既存のファイルで変更するのは `.gitignore` だけである。
- 保つ振る舞い: 既存の行（`.claude/review/`）が git の追跡対象外であること。
- 変わる振る舞い: 配置に挙げた5つのパターン（`.venv/`、`__pycache__/`、`.coverage`、`.pytest_cache/`、`.ruff_cache/`）が git の追跡対象外になる。対応する既存テストと受け入れ基準はない。
- なくなる振る舞い: なし。

判断「依存の向き」、配置の数えないファイル、投影の式の書き方の記述を直したが、コードの振る舞いは変わらない。保つ振る舞いは DES-001 のすべてで、変わる振る舞い・なくなる振る舞いはなく、test-items.md の DES-001 の項目も変わらない。

## テスト項目

`docs/project/test-items.md` の「DES-001 フレームの描画（ドーナツ）」

## 判断

| 判断 | 選択肢 | 採用 | 理由 |
|---|---|---|---|
| モジュールの分け方（architecture.md「構成要素と境界」） | (a) 描画計算と図形を別モジュール (b) 1つのモジュール | (a) | 図形を足すときに `spin.shapes` だけを変えればよい（overview.md「制約」） |
| 起動・再生・入口の分け方（architecture.md「構成要素と境界」） | (a) `spin.cli`・`spin.animation`・`spin.__main__` に分ける (b) `spin.__main__` 1つにまとめる | (a) | 解析と検証（REQ-004）、入出力と時間待ちを含む再生（REQ-005）を別々にテストできる。`spin.__main__` はつなぐだけにして、テストしにくい部分を最小にする |
| 依存の向き（architecture.md「依存の向き」） | (a) 入口 → 起動・図形・再生、再生 → 起動、起動 → 図形、図形・再生 → 描画計算の一方向（逆向きなし） (b) 制限しない | (a) | 描画計算を純粋な関数に保ち（tech.md「技術的な制約」）、図形を足しても描画計算と再生を変えずに済む（overview.md「制約」）。`spin.cli` は選べる図形の名前の一覧を `spin.shapes` から得る。入口が図形の点を作って再生に渡す形は DES-005 の判断による |
| 標準ライブラリの使い方（architecture.md「依存の向き」） | (a) 入出力・時刻・端末のモジュールを `spin.rendering`・`spin.shapes` で禁止し、他は自由 (b) モジュールごとに使えるものを列挙する | (a) | 守るべきは純粋さだけで、列挙すると図形を足すたびに更新が要る |
| テストの配置と命名（architecture.md「ディレクトリ構成」「命名規則」） | (a) `tests/test_<モジュール名>.py` (b) 要件ごとのファイル | (a) | pytest の既定の探し方に合い、テストを書く場所がモジュールから一意に決まる |
| 投影の方式 | (a) 透視投影 (b) 平行投影 | (a) | 奥行きが見た目に出て、立体に見える |
| 2π の扱い | (a) 角を 2π で割った余りにしてから計算 (b) 小数の誤差を許してフレームを比べる | (a) | 基準 3 の「文字列として一致」を、誤差に左右されずに満たせる |
| 光源の向き | (a) 上かつ視点の側 `(0, 1/√2, -1/√2)` (b) 視点の真後ろ `(0, 0, -1)` | (a) | (b) では正面の面がすべて最も明るくなり、陰影の変化が見えにくい |
| 視点の距離 | (a) 5.0 (b) 3.0 以下 | (a) | 近すぎるとゆがみが大きい。5.0 なら外接球の接線の傾きが約 0.2 で、ゆがみが小さい |
| 画面に占める割合 | (a) 縦横の半分の 90% (b) 100% | (a) | 端のマスに張り付かず、床関数の端の扱いでもはみ出さない |
| ドーナツの点の数 | (a) 60 × 200 = 12000 点 (b) 90 × 300 = 27000 点 | (a) | 80 × 24 で面に穴が空かない細かさを保ちつつ、REQ-002 の 0.1 秒に余裕を持たせる。速さの確認は REQ-002 の設計で行う |
| 近さが等しい点 | (a) 先に処理した点を残す（真に大きいときだけ更新） (b) 後の点で上書き | (a) | どちらでも結果は毎回同じになる。(a) は比較が1つで済む |
| ビルドバックエンド | (a) hatchling (b) uv_build | (a) | src レイアウトを設定なしで扱え、広く使われている。実行時の依存ではない |
| 2π の確認での小数の比較（test-items.md DES-001 #21） | (a) `==` で完全一致を確かめる (b) `math.isclose` で比べる | (a) | tech.md「技術的な制約」の例外とする。角を 2π で割った余りにする設計の目的は「誤差なく完全に同じ計算になること」で、それを確かめるには完全一致が必要 |
| 入力の型の検証 | (a) `render_frame` では幅・高さが 1 以上かだけを検証する (b) 型も検証する | (a) | 外部からの入力は REQ-004 の起動オプションで検証する（CODE-20）。型は型ヒントで示す |

## 未決事項

（なし）
