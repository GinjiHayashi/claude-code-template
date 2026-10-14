---
status: final
updated: 2026-10-15
related: [REQ-005, REQ-004, DES-001, DES-004]
---
# DES-005 アニメーションの再生

> 実装レベルの粒度で書く。コード本体は書かない。必須項目の定義の正本は guidelines/planning.md。

## 対応要件

- REQ-005 の受け入れ基準 1〜7 のすべて。
- REQ-004 の基準 4・5 のうち、起動のコマンド（`python -m spin`）を通して、誤った指定ではフレームを1つも描かずに終了コード 2 で終わること（DES-004 の「対応要件」で、この設計に回した部分）。

## 概要

起動オプションで決まった図形を、回転角を進めながら描き続ける `spin.animation` と、起動オプションの解析と再生をつなぐ入口 `spin.__main__` を作る。出力先・時間待ち・時刻の取得は外から渡し、テストでは実際に待たずに確かめる（tech.md「技術的な制約」）。

## 配置

作成するファイル（PLAN-14 で数える4つ）:
- `src/spin/animation.py`
- `src/spin/__main__.py`
- `tests/test_animation.py`
- `tests/test_main.py`

## インタフェース

### `spin.animation`

| 名前 | 種類 | 入力 | 出力 | エラー |
|---|---|---|---|---|
| `PlaybackEnvironment` | 不変のデータクラス | `write: Callable[[str], None]`（文字列を画面に書く）、`sleep: Callable[[float], None]`（指定した秒数だけ待つ）、`clock: Callable[[], float]`（単調に増える秒数を返す） | — | — |
| `system_playback_environment()` | 関数 | なし | 実際の端末を使う `PlaybackEnvironment`。`write` は呼ばれた時点の `sys.stdout` に書いて flush する。`sleep` は `time.sleep`、`clock` は `time.monotonic` | なし |
| `play(points, options, environment)` | 関数 | 表面の点の並び `Sequence[SurfacePoint]`（DES-001）、`LaunchOptions`（DES-004。`shape_name` は使わない）、`PlaybackEnvironment` | なし。描くフレーム数に達したとき、または Ctrl+C（`KeyboardInterrupt`）で、カーソルを表示に戻して正常に戻る | Ctrl+C 以外の例外は、カーソルを表示に戻してからそのまま送出する |

### `spin.__main__`

| 名前 | 種類 | 入力 | 出力 | エラー |
|---|---|---|---|---|
| モジュールの実行（`python -m spin`） | 入口 | `sys.argv[1:]` | `parse_launch_options` の結果の図形の点で `play` を実行し、終了コード 0 で終わる | 起動オプションの誤りは `parse_launch_options` のとおり、フレームを描かずに終了コード 2 で終わる |

## データ構造

モジュール内の定数（`spin.animation`。`_` で始め、公開しない）:
- `_X_ANGLE_STEP = 0.04`、`_Z_ANGLE_STEP = 0.02`: 1フレームあたりの回転角の増分（ラジアン。overview.md「スコープ」）。
- `_CLEAR_SCREEN = "\x1b[2J"`、`_HIDE_CURSOR = "\x1b[?25l"`、`_SHOW_CURSOR = "\x1b[?25h"`、`_CURSOR_HOME = "\x1b[H"`: ANSI エスケープシーケンス（REQ-005 の基準 2・4）。

## 処理方針

- **`play` の流れ**:
  1. `write(_CLEAR_SCREEN + _HIDE_CURSOR)` を書く（基準 2）。
  2. フレームの番号 n を 0 から 1 ずつ増やしながら、描くフレーム数が `None` なら終わりなく、そうでなければ `frame_count` 回、次を繰り返す。
     - `start = clock()` を取る。
     - `Rotation(_X_ANGLE_STEP × n, _Z_ANGLE_STEP × n)` で `render_frame(points, rotation, options.width, options.height)` を作る（基準 1）。回転角は前のフレームに足し込まず、毎回 n から計算する（小数の誤差がたまらないようにするため）。
     - `write(_CURSOR_HOME + frame)` を書く（基準 2）。
     - `wait = 1 / options.fps − (clock() − start)` を求め、`wait > 0` のときだけ `sleep(wait)` を呼ぶ（基準 3）。
  3. 繰り返しの中で `KeyboardInterrupt` が起きたら、捕まえて正常に戻る（基準 5・6。標準エラー出力には何も書かない）。
  4. 手順 1 の書き込みから繰り返しの終わりまでを `try … finally` で囲み、終わり方によらず `write(_SHOW_CURSOR + "\n")` を書く（基準 4・6・7）。改行を足すのは、シェルの入力待ちの表示をフレームの次の行から始めるためである。
- Ctrl+C 以外の例外は捕まえない。`finally` でカーソルを戻した後、そのまま送出される（基準 7。終了コードと表示は Python の既定、REQ-005 の判断）。
- **`spin.__main__`**: `parse_launch_options(sys.argv[1:])` を呼び、成功したら `SHAPES[options.shape_name]()` で表面の点を一度だけ作り、`play(points, options, system_playback_environment())` を呼ぶ。解析が先なので、誤った指定ではフレームを1つも描かない（REQ-004 の基準 4・5）。`play` が戻れば、モジュールの実行が終わり終了コード 0 になる（基準 4・6）。
- 採用しなかった案:
  - 回転角を前のフレームに足し込む案は採らなかった。小数の誤差がたまり、基準 1 の「n 番目のフレームの回転角」と一致しなくなるため。
  - Ctrl+C を `signal` で受け取る案は採らなかった。Python は Ctrl+C を `KeyboardInterrupt` として送出するので、それを捕まえれば足りるため。
  - `__main__` に再生の処理を書く案は採らなかった。architecture.md で `spin.__main__` はつなぐだけと決めており、テストしにくい部分を小さくするため。

### 既存の振る舞いへの影響

該当なし（新しいファイルだけを作る）。

## テスト項目

`docs/project/test-items.md` の「DES-005 アニメーションの再生」

## 判断

| 判断 | 選択肢 | 採用 | 理由 |
|---|---|---|---|
| 表面の点の作り方 | (a) `spin.__main__` が `SHAPES` から作って `play` に渡す (b) `play` が図形の名前から作る | (a) | テストで点の少ない並びを渡せるので、基準 5 の 1000 フレームを短い時間で確かめられる（ドーナツの 12000 点では約 15 秒かかる）。`spin.__main__` → `spin.shapes` の依存が増えるため、architecture.md を改訂する（PLAN-23。下の行） |
| architecture.md の改訂（PLAN-23） | (a) 依存の向きに `spin.__main__` → `spin.shapes` と `spin.animation` → `spin.cli` を足し、`spin.animation` → `spin.shapes` を消す (b) 改訂しない（点の生成を `spin.animation` に残す） | (a) | 上の「表面の点の作り方」の判断に合わせる。`spin.animation` は `spin.shapes` を直接使わず、図形を足しても再生を変えずに済む。`spin.animation` → `spin.cli` は、`play` が `LaunchOptions` を受け取るためである（再生用の値を別に定義する案は、同じ項目の型が2つになるので採らなかった）。あわせて、「作る DES」の欄を DES-004・DES-005 に、`pyproject.toml` の注記に coverage を加え、`spin.__main__` のテストファイル名を `tests/test_main.py` と決める。この変更で、DES-001 の判断「依存の向き」が architecture.md と合わなくなるため、DES-001 を改訂する（PLAN-22・PLAN-23）。判断の行を直し、あわせて TASK-003 で残した P2（配置の数えないファイルと投影の式の書き方）を反映する。振る舞いは変えない。DES-004 は `spin.cli` → `spin.shapes` だけに触れ、影響はない |
| 出力・待ち・時刻の差し替え方 | (a) 3つの関数をまとめた `PlaybackEnvironment` を渡す (b) 3つを別々の引数で渡す | (a) | `play` の引数を2つに保てる（CODE-08）。テストでは偽の関数を入れた値を作るだけで済む |
| 経過時間の測り方 | (a) フレームの計算の前から書き終わりまで (b) 計算だけ | (a) | 基準 3 は「計算と出力にかかった時間」を引くと定めている |
| 終了時の改行 | (a) カーソルを戻すときに改行を1つ書く (b) 書かない | (a) | 書かないと、シェルの入力待ちの表示がフレームの最後の行に続いて出てしまう |
| Ctrl+C の扱いの場所 | (a) `play` の中で捕まえる (b) `spin.__main__` で捕まえる | (a) | 偽の `sleep` から `KeyboardInterrupt` を送出するだけでテストでき、`spin.__main__` をつなぐだけに保てる |
| `write` が参照する標準出力 | (a) 呼ばれた時点の `sys.stdout` (b) 環境を作った時点の `sys.stdout` | (a) | テストで標準出力を差し替えたときも、その差し替え先に書ける |

## 未決事項

（なし）
