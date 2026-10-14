"""アニメーションの再生。回転角を進めながらフレームを描き続ける。"""

import itertools
import sys
import time
from collections.abc import Callable, Iterable, Sequence
from dataclasses import dataclass

from spin.cli import LaunchOptions
from spin.rendering import Rotation, SurfacePoint, render_frame

_X_ANGLE_STEP = 0.04
_Z_ANGLE_STEP = 0.02
_CLEAR_SCREEN = "\x1b[2J"
_HIDE_CURSOR = "\x1b[?25l"
_SHOW_CURSOR = "\x1b[?25h"
_CURSOR_HOME = "\x1b[H"


@dataclass(frozen=True)
class PlaybackEnvironment:
    """再生環境。画面に書く手段、待つ手段、時刻を得る手段の組。"""

    write: Callable[[str], None]
    sleep: Callable[[float], None]
    clock: Callable[[], float]


def _write_to_stdout(text: str) -> None:
    """呼ばれた時点の標準出力に書き、すぐに表示されるよう flush する。"""
    sys.stdout.write(text)
    sys.stdout.flush()


def system_playback_environment() -> PlaybackEnvironment:
    """実際の端末を使う再生環境を返す。"""
    return PlaybackEnvironment(
        write=_write_to_stdout, sleep=time.sleep, clock=time.monotonic
    )


def _frame_numbers(frame_count: int | None) -> Iterable[int]:
    """描くフレームの番号を 0 から返す。frame_count が None なら終わりなく返す。"""
    return itertools.count() if frame_count is None else range(frame_count)


def _write_frame(
    points: Sequence[SurfacePoint],
    options: LaunchOptions,
    environment: PlaybackEnvironment,
    number: int,
) -> None:
    """number 番目のフレームを描き、カーソルを左上に戻して書く。"""
    # 前のフレームに足し込まず番号から求め、小数の誤差がたまらないようにする
    rotation = Rotation(_X_ANGLE_STEP * number, _Z_ANGLE_STEP * number)
    frame = render_frame(points, rotation, options.width, options.height)
    environment.write(_CURSOR_HOME + frame)


def _wait_rest_of_interval(
    environment: PlaybackEnvironment, fps: int, start: float
) -> None:
    """1/fps 秒から start 以降の経過時間を引いた残りが正なら、その秒数だけ待つ。"""
    wait = 1 / fps - (environment.clock() - start)
    if wait > 0:
        environment.sleep(wait)


def play(
    points: Sequence[SurfacePoint],
    options: LaunchOptions,
    environment: PlaybackEnvironment,
) -> None:
    """表面の点を回しながらフレームを描き、終わり方によらずカーソルを表示に戻す。"""
    try:
        environment.write(_CLEAR_SCREEN + _HIDE_CURSOR)
        # Ctrl+C は描き続けるときの正規の止め方なので、正常に戻る
        try:
            for number in _frame_numbers(options.frame_count):
                start = environment.clock()
                _write_frame(points, options, environment, number)
                _wait_rest_of_interval(environment, options.fps, start)
        except KeyboardInterrupt:
            pass
    finally:
        environment.write(_SHOW_CURSOR + "\n")
