import pytest

from warikan.calc import (
    CollectExtraSplit,
    OrganizerPaysSplit,
    split_collect_extra,
    split_organizer_pays,
)

EXHAUSTIVE_TOTALS = [1, 99, 100, 101, 9999, 10000, 999999, 1000000]
EXHAUSTIVE_PEOPLE = range(1, 101)


def test_des001_1_typical_split():
    assert split_organizer_pays(10000, 3) == OrganizerPaysSplit(
        per_person=3300, organizer_payment=3400
    )


def test_des001_2_divisible_total():
    assert split_organizer_pays(9000, 3) == OrganizerPaysSplit(
        per_person=3000, organizer_payment=3000
    )


def test_des001_3_per_person_zero():
    assert split_organizer_pays(250, 3) == OrganizerPaysSplit(
        per_person=0, organizer_payment=250
    )


def test_des001_4_single_person():
    assert split_organizer_pays(10050, 1) == OrganizerPaysSplit(
        per_person=10000, organizer_payment=10050
    )


@pytest.mark.parametrize("total", EXHAUSTIVE_TOTALS)
@pytest.mark.parametrize("people", EXHAUSTIVE_PEOPLE)
def test_des001_5_exhaustive_invariants(total, people):
    split = split_organizer_pays(total, people)

    assert split.per_person * (people - 1) + split.organizer_payment == total
    assert split.per_person % 100 == 0
    assert split.per_person * people <= total < (split.per_person + 100) * people


def test_des001_6_minimum():
    assert split_organizer_pays(1, 1) == OrganizerPaysSplit(
        per_person=0, organizer_payment=1
    )


@pytest.mark.parametrize(
    ("total", "people", "expected"),
    [
        (2, 1, OrganizerPaysSplit(per_person=0, organizer_payment=2)),
        (2, 2, OrganizerPaysSplit(per_person=0, organizer_payment=2)),
        (1, 2, OrganizerPaysSplit(per_person=0, organizer_payment=1)),
    ],
)
def test_des001_7_just_above_minimum(total, people, expected):
    assert split_organizer_pays(total, people) == expected


def test_des001_8_maximum():
    assert split_organizer_pays(1000000, 100) == OrganizerPaysSplit(
        per_person=10000, organizer_payment=10000
    )


@pytest.mark.parametrize("total", [0, 1000001])
def test_des001_9_total_out_of_range(total):
    with pytest.raises(ValueError) as excinfo:
        split_organizer_pays(total, 3)

    assert "合計金額" in str(excinfo.value)
    assert "1〜1,000,000" in str(excinfo.value)


@pytest.mark.parametrize("people", [0, 101])
def test_des001_10_people_out_of_range(people):
    with pytest.raises(ValueError) as excinfo:
        split_organizer_pays(10000, people)

    assert "人数" in str(excinfo.value)
    assert "1〜100" in str(excinfo.value)


def test_des001_11_negative_total():
    with pytest.raises(ValueError) as excinfo:
        split_organizer_pays(-1, 3)

    assert "合計金額" in str(excinfo.value)
    assert "1〜1,000,000" in str(excinfo.value)


def test_des001_11_negative_people():
    with pytest.raises(ValueError) as excinfo:
        split_organizer_pays(10000, -1)

    assert "人数" in str(excinfo.value)
    assert "1〜100" in str(excinfo.value)


@pytest.mark.parametrize("total", ["10000", None, 1.5, True])
def test_des001_12_total_wrong_type(total):
    with pytest.raises(TypeError) as excinfo:
        split_organizer_pays(total, 3)

    assert "合計金額" in str(excinfo.value)
    assert "整数" in str(excinfo.value)


@pytest.mark.parametrize("people", ["3", None, 3.0, True])
def test_des001_13_people_wrong_type(people):
    with pytest.raises(TypeError) as excinfo:
        split_organizer_pays(10000, people)

    assert "人数" in str(excinfo.value)
    assert "整数" in str(excinfo.value)


def test_des001_14_extremely_large_total():
    with pytest.raises(ValueError) as excinfo:
        split_organizer_pays(10**100, 3)

    assert "合計金額" in str(excinfo.value)


def test_des001_15_total_checked_before_people():
    with pytest.raises(ValueError) as excinfo:
        split_organizer_pays(0, 0)

    assert "合計金額" in str(excinfo.value)
    assert "人数" not in str(excinfo.value)


@pytest.mark.parametrize("total", EXHAUSTIVE_TOTALS)
@pytest.mark.parametrize("people", EXHAUSTIVE_PEOPLE)
def test_des003_4_exhaustive_invariants(total, people):
    split = split_collect_extra(total, people)

    assert split.per_person * people - split.surplus == total
    assert split.per_person % 100 == 0
    assert (split.per_person - 100) * people < total <= split.per_person * people


@pytest.mark.parametrize(
    ("total", "people", "expected"),
    [
        pytest.param(
            10000, 3, CollectExtraSplit(per_person=3400, surplus=200), id="1_typical"
        ),
        pytest.param(
            9000, 3, CollectExtraSplit(per_person=3000, surplus=0), id="2_divisible"
        ),
        pytest.param(
            10050,
            1,
            CollectExtraSplit(per_person=10100, surplus=50),
            id="3_single_person",
        ),
        pytest.param(
            1, 1, CollectExtraSplit(per_person=100, surplus=99), id="5_minimum"
        ),
        pytest.param(
            2, 1, CollectExtraSplit(per_person=100, surplus=98), id="6_above_min_total"
        ),
        pytest.param(
            1,
            2,
            CollectExtraSplit(per_person=100, surplus=199),
            id="6_above_min_people",
        ),
        pytest.param(
            1000000, 100, CollectExtraSplit(per_person=10000, surplus=0), id="7_maximum"
        ),
        pytest.param(
            999999,
            100,
            CollectExtraSplit(per_person=10000, surplus=1),
            id="7_below_max",
        ),
    ],
)
def test_des003_1_2_3_5_6_7_fixed_cases(total, people, expected):
    assert split_collect_extra(total, people) == expected


@pytest.mark.parametrize("total", [0, 1000001, -1])
def test_des003_8_9_total_out_of_range(total):
    with pytest.raises(ValueError) as excinfo:
        split_collect_extra(total, 3)

    assert "合計金額" in str(excinfo.value)
    assert "1〜1,000,000" in str(excinfo.value)


@pytest.mark.parametrize("people", [0, 101, -1])
def test_des003_8_9_people_out_of_range(people):
    with pytest.raises(ValueError) as excinfo:
        split_collect_extra(10000, people)

    assert "人数" in str(excinfo.value)
    assert "1〜100" in str(excinfo.value)


@pytest.mark.parametrize("total", ["10000", None, 1.5, True])
def test_des003_10_total_wrong_type(total):
    with pytest.raises(TypeError) as excinfo:
        split_collect_extra(total, 3)

    assert "合計金額" in str(excinfo.value)
    assert "整数" in str(excinfo.value)


@pytest.mark.parametrize("people", ["3", None, 3.0, True])
def test_des003_10_people_wrong_type(people):
    with pytest.raises(TypeError) as excinfo:
        split_collect_extra(10000, people)

    assert "人数" in str(excinfo.value)
    assert "整数" in str(excinfo.value)


def test_des003_10_extremely_large_total():
    with pytest.raises(ValueError) as excinfo:
        split_collect_extra(10**100, 3)

    assert "合計金額" in str(excinfo.value)


def test_des003_11_total_checked_before_people():
    with pytest.raises(ValueError) as excinfo:
        split_collect_extra(0, 0)

    assert "合計金額" in str(excinfo.value)
    assert "人数" not in str(excinfo.value)
