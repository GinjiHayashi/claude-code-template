"""起動オプションの解析と検証。"""

import argparse
import re
from collections.abc import Sequence
from dataclasses import dataclass

from spin.shapes import SHAPES

_DEFAULT_SHAPE_NAME = "torus"
_DEFAULT_WIDTH = 80
_DEFAULT_HEIGHT = 24
_DEFAULT_FPS = 20
# int() は "+5"・"1_000"・全角数字も受け付けるため、半角数字だけを許す
_DIGITS = re.compile(r"[0-9]+")


@dataclass(frozen=True)
class LaunchOptions:
    """起動オプション。図形の名前、幅、高さ、フレームレート、描くフレーム数を持つ。"""

    shape_name: str
    width: int
    height: int
    fps: int
    frame_count: int | None


def _positive_integer(text: str) -> int:
    """半角数字だけからなる 1 以上の整数を返す。それ以外は ArgumentTypeError。"""
    if _DIGITS.fullmatch(text) is None or int(text) < 1:
        raise argparse.ArgumentTypeError(f"正の整数を指定する: {text!r}")
    return int(text)


def _build_parser() -> argparse.ArgumentParser:
    """起動オプションの解析器を作る。"""
    parser = argparse.ArgumentParser(prog="spin", allow_abbrev=False)
    parser.add_argument(
        "shape_name", nargs="?", default=_DEFAULT_SHAPE_NAME, choices=list(SHAPES)
    )
    parser.add_argument("--width", type=_positive_integer, default=_DEFAULT_WIDTH)
    parser.add_argument("--height", type=_positive_integer, default=_DEFAULT_HEIGHT)
    parser.add_argument("--fps", type=_positive_integer, default=_DEFAULT_FPS)
    parser.add_argument(
        "--frames", dest="frame_count", type=_positive_integer, default=None
    )
    return parser


def parse_launch_options(arguments: Sequence[str]) -> LaunchOptions:
    """起動のコマンドに続く文字列の並びを解析する。

    誤りなら SystemExit(2)、--help なら使い方を表示して SystemExit(0)。
    """
    namespace = _build_parser().parse_args(list(arguments))
    return LaunchOptions(
        shape_name=namespace.shape_name,
        width=namespace.width,
        height=namespace.height,
        fps=namespace.fps,
        frame_count=namespace.frame_count,
    )
