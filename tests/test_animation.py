"""spin.animation のテスト（DES-005）。偽の再生環境で、実際には待たずに確かめる。"""

import dataclasses
import time

import pytest

from spin.animation import PlaybackEnvironment, play, system_playback_environment
from spin.cli import LaunchOptions
from spin.rendering import LIGHT_DIRECTION, Rotation, SurfacePoint, render_frame
from spin.shapes import SHAPES

HOME = "\x1b[H"
CLEAR = "\x1b[2J"
HIDE = "\x1b[?25l"
SHOW = "\x1b[?25h"
ENDING = SHOW + "\n"


class FakeEnvironment:
    """書き込みと待ち時間を記録し、決めた時刻を順に返す偽の再生環境。"""

    def __init__(self, times: list[float] | None = None) -> None:
        self.writes: list[str] = []
        self.sleeps: list[float] = []
        self._times = iter(times) if times is not None else None

    def write(self, text: str) -> None:
        self.writes.append(text)

    def sleep(self, seconds: float) -> None:
        self.sleeps.append(seconds)

    def clock(self) -> float:
        return 0.0 if self._times is None else next(self._times)

    def build(self) -> PlaybackEnvironment:
        return PlaybackEnvironment(write=self.write, sleep=self.sleep, clock=self.clock)

    def frame_writes(self) -> list[str]:
        return [text for text in self.writes if text.startswith(HOME)]


def _one_point() -> tuple[SurfacePoint, ...]:
    return (SurfacePoint(position=(0.0, 0.0, 0.0), normal=LIGHT_DIRECTION),)


def _options(
    frame_count: int | None, width: int = 20, height: int = 10
) -> LaunchOptions:
    return LaunchOptions(
        shape_name="torus", width=width, height=height, fps=20, frame_count=frame_count
    )


def test_frames_follow_rotation_steps():
    """DES-005 #1 n 番目のフレームを回転角 (0.04n, 0.02n) で描く。"""
    points = SHAPES["torus"]()
    fake = FakeEnvironment()

    play(points, _options(3), fake.build())

    expected_frames = [
        HOME + render_frame(points, Rotation(0.04 * n, 0.02 * n), 20, 10)
        for n in range(3)
    ]
    assert fake.writes == [CLEAR + HIDE, *expected_frames, ENDING]


def test_waits_for_remaining_frame_interval():
    """DES-005 #2 1/フレームレート から経過時間を引いた秒数だけ待つ。"""
    fake = FakeEnvironment(times=[0.0, 0.01] * 3)

    play(_one_point(), _options(3), fake.build())

    assert fake.sleeps == pytest.approx([0.04, 0.04, 0.04])


def test_does_not_wait_when_frame_takes_full_interval():
    """DES-005 #3 経過時間が間隔ちょうど、または間隔より長いときは待たない。"""
    fake = FakeEnvironment(times=[0.0, 0.05, 0.0, 0.2])

    play(_one_point(), _options(2), fake.build())

    assert fake.sleeps == []


def test_single_frame_then_cursor_is_shown():
    """DES-005 #4 描くフレーム数 1 では、フレームを1つ書いてカーソルを戻す。"""
    fake = FakeEnvironment()

    play(_one_point(), _options(1), fake.build())

    assert len(fake.frame_writes()) == 1
    assert fake.writes[-1] == ENDING


def test_unlimited_frames_continue_until_interrupted():
    """DES-005 #5 描くフレーム数の指定がなければ、Ctrl+C まで描き続ける。"""
    fake = FakeEnvironment()

    def sleep_until_thousandth(seconds: float) -> None:
        fake.sleeps.append(seconds)
        if len(fake.sleeps) == 1000:
            raise KeyboardInterrupt

    environment = PlaybackEnvironment(
        write=fake.write, sleep=sleep_until_thousandth, clock=fake.clock
    )

    play(_one_point(), _options(None), environment)

    assert len(fake.frame_writes()) == 1000
    assert fake.writes[-1] == ENDING


def test_interrupt_ends_quietly_and_shows_cursor(capsys):
    """DES-005 #6 Ctrl+C では標準エラー出力に何も書かず、カーソルを戻して正常に戻る。"""
    fake = FakeEnvironment()

    def interrupt(seconds: float) -> None:
        raise KeyboardInterrupt

    environment = PlaybackEnvironment(
        write=fake.write, sleep=interrupt, clock=fake.clock
    )

    play(_one_point(), _options(3), environment)

    assert fake.writes[-1] == ENDING
    assert capsys.readouterr().err == ""


def test_other_error_while_waiting_shows_cursor_and_propagates():
    """DES-005 #7 待つ間の Ctrl+C 以外の例外は、カーソルを戻してから送出する。"""
    fake = FakeEnvironment()

    def fail(seconds: float) -> None:
        raise RuntimeError("待てない")

    environment = PlaybackEnvironment(write=fake.write, sleep=fail, clock=fake.clock)

    with pytest.raises(RuntimeError):
        play(_one_point(), _options(3), environment)

    assert fake.writes[-1] == ENDING


def test_other_error_while_writing_shows_cursor_and_propagates():
    """DES-005 #8 フレームを書く間に例外が起きても、カーソルを戻してから送出する。"""
    fake = FakeEnvironment()
    calls = []

    def write_failing_on_first_frame(text: str) -> None:
        calls.append(text)
        if len(calls) == 2:
            raise RuntimeError("書けない")
        fake.write(text)

    environment = PlaybackEnvironment(
        write=write_failing_on_first_frame, sleep=fake.sleep, clock=fake.clock
    )

    with pytest.raises(RuntimeError):
        play(_one_point(), _options(3), environment)

    assert fake.writes[-1] == ENDING


def test_empty_points_draw_blank_frame():
    """DES-005 #9 表面の点が空なら、空白だけのフレームを書く。"""
    fake = FakeEnvironment()

    play((), _options(1, width=4, height=2), fake.build())

    assert fake.frame_writes() == [HOME + "    \n    "]


def test_playback_environment_is_immutable():
    """DES-005 #10 PlaybackEnvironment の属性には代入できない。"""
    environment = FakeEnvironment().build()

    with pytest.raises(dataclasses.FrozenInstanceError):
        environment.write = print


def test_system_environment_uses_stdout_and_time(capsys):
    """DES-005 #11 実際の端末の再生環境は、標準出力と time の関数を使う。"""
    environment = system_playback_environment()

    environment.write("abc")

    assert capsys.readouterr().out == "abc"
    assert environment.sleep is time.sleep
    assert environment.clock is time.monotonic
