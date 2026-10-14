import subprocess
import sys

import pytest

from warikan.cli import main


def test_des002_1_typical_split(capsys):
    exit_code = main(["10000", "3"])

    assert exit_code == 0
    assert capsys.readouterr().out == "1人あたり 3,300円\n幹事 3,400円\n"


def test_des002_2_explicit_method(capsys):
    exit_code = main(["10000", "3", "--method", "organizer-pays"])

    assert exit_code == 0
    assert capsys.readouterr().out == "1人あたり 3,300円\n幹事 3,400円\n"


def test_des002_3_divisible_total(capsys):
    exit_code = main(["9000", "3"])

    assert exit_code == 0
    assert capsys.readouterr().out == "1人あたり 3,000円\n幹事 3,000円\n"


def test_des002_4_per_person_zero(capsys):
    exit_code = main(["250", "3"])

    assert exit_code == 0
    assert capsys.readouterr().out == "1人あたり 0円\n幹事 250円\n"


def test_des002_5_single_person(capsys):
    exit_code = main(["10050", "1"])

    assert exit_code == 0
    assert capsys.readouterr().out == "1人あたり 10,000円\n幹事 10,050円\n"


@pytest.mark.parametrize(
    ("argv", "expected_out"),
    [
        (["1000000", "1"], "1人あたり 1,000,000円\n幹事 1,000,000円\n"),
        (["1", "1"], "1人あたり 0円\n幹事 1円\n"),
        (["1000000", "100"], "1人あたり 10,000円\n幹事 10,000円\n"),
    ],
)
def test_des002_6_amount_format_boundaries(capsys, argv, expected_out):
    exit_code = main(argv)

    assert exit_code == 0
    assert capsys.readouterr().out == expected_out


def test_des002_7_module_entry_point():
    completed = subprocess.run(
        [sys.executable, "-m", "warikan", "10000", "3"],
        capture_output=True,
        text=True,
        check=False,
        timeout=30,
    )

    assert completed.returncode == 0
    assert completed.stdout == "1人あたり 3,300円\n幹事 3,400円\n"
    assert completed.stderr == ""


@pytest.mark.parametrize(
    ("argv", "expected_out"),
    [
        pytest.param(
            ["10000", "3", "--method", "collect-extra"],
            "1人あたり 3,400円\n余り 200円\n",
            id="12_typical",
        ),
        pytest.param(
            ["9000", "3", "--method", "collect-extra"],
            "1人あたり 3,000円\n余り 0円\n",
            id="13_divisible",
        ),
        pytest.param(
            ["10050", "1", "--method", "collect-extra"],
            "1人あたり 10,100円\n余り 50円\n",
            id="13_single_person",
        ),
        pytest.param(
            ["1000000", "1", "--method", "collect-extra"],
            "1人あたり 1,000,000円\n余り 0円\n",
            id="14_comma_two",
        ),
        pytest.param(
            ["1", "1", "--method", "collect-extra"],
            "1人あたり 100円\n余り 99円\n",
            id="14_minimum",
        ),
        pytest.param(
            ["1000000", "100", "--method", "collect-extra"],
            "1人あたり 10,000円\n余り 0円\n",
            id="14_max_people",
        ),
        pytest.param(
            ["--method", "collect-extra", "10000", "3"],
            "1人あたり 3,400円\n余り 200円\n",
            id="15_option_first",
        ),
    ],
)
def test_des003_12to15_collect_extra_output(capsys, argv, expected_out):
    exit_code = main(argv)

    assert exit_code == 0
    assert capsys.readouterr().out == expected_out


def _assert_input_error(capsys, argv, expected_fragments):
    exit_code = main(argv)

    captured = capsys.readouterr()
    assert exit_code == 1
    assert captured.out == ""
    for fragment in expected_fragments:
        assert fragment in captured.err


@pytest.mark.parametrize(
    ("argv", "expected_fragments"),
    [
        pytest.param(["abc", "3"], ["合計金額", "整数"], id="1_total_letters"),
        pytest.param(["3.5", "3"], ["合計金額", "整数"], id="2_total_decimal"),
        pytest.param(["10,000", "3"], ["合計金額", "整数"], id="3_total_comma"),
        pytest.param(["１０００", "3"], ["合計金額", "整数"], id="4_total_fullwidth"),
        pytest.param(["10000", "+3"], ["人数", "整数"], id="5_people_plus_sign"),
        pytest.param(["0", "3"], ["合計金額", "1〜1,000,000"], id="6_total_zero"),
        pytest.param(
            ["1000001", "3"], ["合計金額", "1〜1,000,000"], id="6_total_over_max"
        ),
        pytest.param(["10000", "x"], ["人数", "整数"], id="7_people_letter"),
        pytest.param(["10000", "0"], ["人数", "1〜100"], id="8_people_zero"),
        pytest.param(["10000", "101"], ["人数", "1〜100"], id="8_people_over_max"),
        pytest.param(
            ["10000", "3", "--method", "foo"],
            ["方式", "幹事負担", "多めに集める"],
            id="9_unknown_method",
        ),
        pytest.param(["10000"], ["人数", "指定"], id="10_people_missing"),
        pytest.param([], ["合計金額", "指定"], id="11_both_missing"),
        pytest.param(["10000", "3", "5"], ["引数"], id="12_extra_argument"),
        pytest.param(["10000", "3", "--foo"], ["オプション"], id="13_unknown_option"),
        pytest.param(["10000", "3", "--method"], ["引数"], id="14_method_no_value"),
        pytest.param(["", "3"], ["合計金額", "整数"], id="15_total_empty"),
        pytest.param(["-1", "3"], ["合計金額", "整数"], id="16_total_negative"),
        pytest.param(
            ["1" * 10000, "3"], ["合計金額", "20文字"], id="17_total_long_digits"
        ),
        pytest.param(
            ["a" * 10000, "3"], ["合計金額", "20文字"], id="17_total_long_letters"
        ),
        pytest.param(
            ["10000", "1" * 10000], ["人数", "20文字"], id="17_people_long_digits"
        ),
        pytest.param(
            ["10000; rm -rf /", "3"], ["合計金額", "整数"], id="18_total_injection"
        ),
        pytest.param(["1\n0", "3"], ["合計金額", "整数"], id="18_total_newline"),
        pytest.param(["²", "3"], ["合計金額", "整数"], id="18_total_superscript"),
        pytest.param(["١٢", "3"], ["合計金額", "整数"], id="18_total_arabic_digits"),
        pytest.param(["10000", "3", "-5"], ["オプション"], id="20_negative_extra"),
        pytest.param(
            ["10000", "3", "--meth", "collect-extra"],
            ["オプション"],
            id="20_abbreviated_option",
        ),
        pytest.param(["10000", ""], ["人数", "整数"], id="21_people_empty"),
        pytest.param(
            ["000000000000000010000", "3"],
            ["合計金額", "20文字"],
            id="22_total_21_chars",
        ),
        pytest.param(
            ["10000", "000000000000000000003"],
            ["人数", "20文字"],
            id="22_people_21_chars",
        ),
    ],
)
def test_des004_invalid_input(capsys, argv, expected_fragments):
    _assert_input_error(capsys, argv, expected_fragments)


def test_des004_19_total_reported_before_people(capsys):
    exit_code = main(["abc", "x"])

    captured = capsys.readouterr()
    assert exit_code == 1
    assert captured.out == ""
    assert "合計金額" in captured.err
    assert "人数" not in captured.err


@pytest.mark.parametrize(
    ("argv", "expected_out"),
    [
        pytest.param(
            ["00000000000000010000", "3"],
            "1人あたり 3,300円\n幹事 3,400円\n",
            id="22_total_20_chars",
        ),
        pytest.param(
            ["10000", "00000000000000000003"],
            "1人あたり 3,300円\n幹事 3,400円\n",
            id="22_people_20_chars",
        ),
        pytest.param(
            ["010000", "3"],
            "1人あたり 3,300円\n幹事 3,400円\n",
            id="23_leading_zero",
        ),
        pytest.param(
            ["10000", "3", "--method", "collect-extra", "--method", "organizer-pays"],
            "1人あたり 3,300円\n幹事 3,400円\n",
            id="24_duplicate_option",
        ),
        pytest.param(
            ["10000", "--method", "collect-extra", "3"],
            "1人あたり 3,400円\n余り 200円\n",
            id="25_option_between_positionals",
        ),
    ],
)
def test_des004_valid_edge_input(capsys, argv, expected_out):
    exit_code = main(argv)

    assert exit_code == 0
    assert capsys.readouterr().out == expected_out


def test_des004_26_help(capsys):
    with pytest.raises(SystemExit) as excinfo:
        main(["-h"])

    assert excinfo.value.code == 0
    assert (
        "total people [--method {organizer-pays,collect-extra}]"
        in capsys.readouterr().out
    )


def test_des004_27_module_entry_point_error():
    completed = subprocess.run(
        [sys.executable, "-m", "warikan", "abc", "3"],
        capture_output=True,
        text=True,
        check=False,
        timeout=30,
    )

    assert completed.returncode == 1
    assert completed.stdout == ""
    assert completed.stderr.startswith("エラー: ")
    assert "Traceback" not in completed.stderr
    assert "合計金額" in completed.stderr
    assert "整数" in completed.stderr
