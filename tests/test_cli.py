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
