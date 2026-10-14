"""spin.cli のテスト（DES-004）。起動オプションの解析と検証を確かめる。"""

import dataclasses

import pytest

from spin import shapes
from spin.cli import LaunchOptions, parse_launch_options

NUMERIC_OPTIONS = ("--width", "--height", "--fps", "--frames")


def _assert_rejected(arguments: list[str], capsys: pytest.CaptureFixture) -> str:
    """解析が終了コード 2・標準出力なしで終わることを確かめ、標準エラー出力を返す。"""
    with pytest.raises(SystemExit) as exit_info:
        parse_launch_options(arguments)

    captured = capsys.readouterr()
    assert exit_info.value.code == 2
    assert captured.out == ""
    return captured.err


def test_defaults_without_arguments():
    """DES-004 #1 何も指定しないと既定値になる。"""
    assert parse_launch_options([]) == LaunchOptions(
        shape_name="torus", width=80, height=24, fps=20, frame_count=None
    )


def test_all_options_are_parsed():
    """DES-004 #2 図形と4つの数値のオプションを解析する。"""
    arguments = [
        "torus",
        "--width",
        "40",
        "--height",
        "10",
        "--fps",
        "5",
        "--frames",
        "3",
    ]

    options = parse_launch_options(arguments)

    assert options == LaunchOptions(
        shape_name="torus", width=40, height=10, fps=5, frame_count=3
    )


def test_minimum_positive_values_are_accepted():
    """DES-004 #3 すべての数値に 1 を指定できる。"""
    arguments = ["--width", "1", "--height", "1", "--fps", "1", "--frames", "1"]

    options = parse_launch_options(arguments)

    assert (options.width, options.height, options.fps, options.frame_count) == (
        1,
        1,
        1,
        1,
    )


@pytest.mark.parametrize(
    "arguments, field, expected",
    [
        pytest.param(["--width", "007"], "width", 7, id="DES-004#4 先頭の0"),
        pytest.param(
            ["--frames", "100000"], "frame_count", 100000, id="DES-004#4 大きな値"
        ),
    ],
)
def test_digit_strings_are_read_as_integers(arguments, field, expected):
    """DES-004 #4 先頭に 0 がある数字や大きな数字も整数として読む。"""
    assert getattr(parse_launch_options(arguments), field) == expected


def test_unknown_shape_lists_all_shape_names(capsys):
    """DES-004 #5 選べない図形の名前では、選べるすべての名前を表示して終わる。"""
    error = _assert_rejected(["sphere"], capsys)

    # 使い方の行にも名前が出るため、誤りの理由の行に名前が並ぶことを確かめる
    reason = next(line for line in error.splitlines() if "invalid choice" in line)
    for name in shapes.SHAPES:
        assert name in reason


@pytest.mark.parametrize(
    "option", [pytest.param(o, id=f"DES-004#6 {o}") for o in NUMERIC_OPTIONS]
)
@pytest.mark.parametrize(
    "value", [pytest.param(v, id=f"DES-004#6 {v}") for v in ("0", "-1", "1.5", "abc")]
)
def test_value_other_than_positive_integer_is_rejected(option, value, capsys):
    """DES-004 #6 数値のオプションに正の整数以外を指定すると、理由を表示して終わる。"""
    error = _assert_rejected([option, value], capsys)

    assert f"argument {option}: 正の整数" in error


@pytest.mark.parametrize(
    "value",
    [
        pytest.param("+5", id="DES-004#7 符号"),
        pytest.param(" 5", id="DES-004#7 空白"),
        pytest.param("1_000", id="DES-004#7 下線"),
        pytest.param("５", id="DES-004#7 全角"),
        pytest.param("", id="DES-004#7 空文字"),
    ],
)
def test_integer_like_strings_are_rejected(value, capsys):
    """DES-004 #7 半角数字以外を含む値は、正の整数として受け付けない。"""
    error = _assert_rejected(["--width", value], capsys)

    assert "argument --width: 正の整数" in error


@pytest.mark.parametrize(
    "shape_name",
    [
        pytest.param("", id="DES-004#8 空文字"),
        pytest.param("torus\x1b[2J", id="DES-004#8 制御文字"),
    ],
)
def test_malformed_shape_name_is_rejected(shape_name, capsys):
    """DES-004 #8 空文字や制御文字を含む図形の名前は受け付けない。"""
    error = _assert_rejected([shape_name], capsys)

    assert "invalid choice" in error


@pytest.mark.parametrize(
    "arguments",
    [
        pytest.param(["--speed", "3"], id="DES-004#9 知らないオプション"),
        pytest.param(["torus", "torus"], id="DES-004#9 余分な位置引数"),
        pytest.param(["--width"], id="DES-004#9 値がない"),
        pytest.param(["--wid", "40"], id="DES-004#9 略記"),
    ],
)
def test_malformed_arguments_are_rejected(arguments, capsys):
    """DES-004 #9 知らないオプション、余分な引数、値の欠け、略記は誤りになる。"""
    # 理由の文字列は入力の並びで argparse が変えるため、終了コードと標準出力で確かめる
    _assert_rejected(arguments, capsys)


def test_repeated_option_uses_last_value():
    """DES-004 #10 同じオプションを2回指定すると、後の値を使う。"""
    assert parse_launch_options(["--width", "40", "--width", "50"]).width == 50


def test_launch_options_are_immutable():
    """DES-004 #11 LaunchOptions の属性には代入できない。"""
    options = parse_launch_options([])

    with pytest.raises(dataclasses.FrozenInstanceError):
        options.width = 1


def test_help_prints_usage_and_exits_successfully(capsys):
    """DES-004 #13 --help は使い方を標準出力に書き、終了コード 0 で終わる。"""
    with pytest.raises(SystemExit) as exit_info:
        parse_launch_options(["--help"])

    output = capsys.readouterr().out
    assert exit_info.value.code == 0
    assert "usage: spin" in output
    for option in NUMERIC_OPTIONS:
        assert option in output
