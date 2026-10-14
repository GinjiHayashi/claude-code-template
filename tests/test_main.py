"""spin.__main__ のテスト（DES-005）。モジュールの実行を通して確かめる。"""

import runpy
import sys

import pytest

HOME = "\x1b[H"
CLEAR = "\x1b[2J"
HIDE = "\x1b[?25l"
SHOW = "\x1b[?25h"


def _run_spin(monkeypatch: pytest.MonkeyPatch, arguments: list[str]) -> None:
    monkeypatch.setattr(sys, "argv", ["spin", *arguments])
    runpy.run_module("spin", run_name="__main__")


def test_running_module_draws_requested_frames(monkeypatch, capsys):
    """DES-005 #12 起動のコマンドで、指定した数のフレームを描いて正常に終わる。"""
    arguments = ["--frames", "2", "--width", "10", "--height", "4", "--fps", "1000"]

    _run_spin(monkeypatch, arguments)

    captured = capsys.readouterr()
    assert captured.out.startswith(CLEAR + HIDE)
    assert captured.out.endswith(SHOW + "\n")
    assert captured.out.count(HOME) == 2
    assert captured.err == ""


@pytest.mark.parametrize(
    "arguments",
    [
        pytest.param(["sphere"], id="DES-005#13 選べない図形"),
        pytest.param(["--width", "0"], id="DES-005#13 正の整数でない幅"),
    ],
)
def test_invalid_options_exit_without_drawing(monkeypatch, capsys, arguments):
    """DES-005 #13 誤った指定では、フレームを描かずに終了コード 2 で終わる。"""
    with pytest.raises(SystemExit) as exit_info:
        _run_spin(monkeypatch, arguments)

    assert exit_info.value.code == 2
    assert capsys.readouterr().out == ""
