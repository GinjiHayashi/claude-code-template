---
status: final
updated: 2026-10-15
related: [DES-001, DES-004, DES-005]
---
# アーキテクチャ・構造

## 構成要素と境界

| 要素 | モジュール | 責務 | 作る DES |
|---|---|---|---|
| 描画計算 | `spin.rendering` | 表面の点の回転・投影・明るさの計算と、1フレームの文字列の組み立て。入出力・時刻・端末に依存しない純粋な関数だけを持つ | DES-001 |
| 図形 | `spin.shapes` | 図形ごとの表面の点の生成と、選べる図形の一覧（図形の名前から生成関数を引く表）。図形を足すときはこのモジュールだけを変える | DES-001 |
| 起動オプション | `spin.cli` | 起動オプションの解析と検証 | DES-004 |
| アニメーションの再生 | `spin.animation` | フレームの連続描画、待ち時間、画面への出力、Ctrl+C の扱い。出力先・時間待ち・時刻の取得は、引数（再生環境）で差し替えられるようにする | DES-005 |
| 入口 | `spin.__main__` | `python -m spin` の入口。起動オプションの解析、選んだ図形の表面の点の生成、アニメーションの再生をつなぐだけ | DES-005 |

## 依存の向き

- `spin.__main__` → `spin.cli`、`spin.shapes`（選んだ図形の表面の点を作るため）、`spin.animation`
- `spin.animation` → `spin.rendering`、`spin.cli`（再生の条件 `LaunchOptions` を受け取るため）
- `spin.cli` → `spin.shapes`（図形の名前の一覧を得るため）
- `spin.shapes` → `spin.rendering`（表面の点の型と外接球の半径を使うため）
- `spin.rendering` → パッケージ内のモジュールには依存しない

上の矢印は、パッケージ内のモジュールどうしの依存の向きである。

禁止する依存:
- パッケージ内のモジュールどうしで、上に挙げていない向きの依存（逆向きを含む）。特に `spin.rendering` から `spin.shapes` を使うこと（図形を足しても描画計算を変えずに済むようにするため。overview.md「制約」）。
- `spin.rendering` と `spin.shapes` から、次の許可リスト以外の標準ライブラリを使うこと: `math`、`dataclasses`、`types`、`typing`、`collections.abc`（tech.md「技術的な制約」の純粋な関数の制約を守るため。入出力・時刻・端末・乱数のモジュールを入れない）。

`spin.rendering` と `spin.shapes` 以外のモジュールは、標準ライブラリをどれでも使ってよい。標準ライブラリ以外の実行時の依存は追加しない（tech.md「技術的な制約」）。

## ディレクトリ構成

```
pyproject.toml        # パッケージ定義と pytest・coverage・Ruff の設定
src/spin/             # パッケージ本体（src レイアウト）
  __init__.py
  rendering.py
  shapes.py
  cli.py
  animation.py
  __main__.py
tests/                # テスト。モジュールごとに test_<モジュール名>.py（spin.__main__ は test_main.py）
```

## 命名規則

- モジュール・関数・変数: 小文字のスネークケース（例: `render_frame`）。
- クラス: パスカルケース（例: `SurfacePoint`）。
- 定数: 大文字のスネークケース（例: `SHADE_CHARS`）。
- 図形の名前（起動オプションと選べる図形の一覧のキー）: glossary.md の「コード上の名前」をケバブケースにしたもの（例: `mobius-strip`）。
- テストファイル: `tests/test_<モジュール名>.py`。`spin.__main__` のテストは、前後の下線を除いて `tests/test_main.py` とする。テスト関数: `test_<確かめる振る舞い>`（TEST-09）。
