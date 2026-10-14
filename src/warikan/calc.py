from dataclasses import dataclass

MIN_TOTAL = 1
MAX_TOTAL = 1_000_000
MIN_PEOPLE = 1
MAX_PEOPLE = 100
ROUNDING_UNIT = 100

_TOTAL_LABEL = "合計金額"
_PEOPLE_LABEL = "人数"


@dataclass(frozen=True)
class OrganizerPaysSplit:
    per_person: int
    organizer_payment: int


def split_organizer_pays(total: int, people: int) -> OrganizerPaysSplit:
    _require_int(total, _TOTAL_LABEL)
    _require_int(people, _PEOPLE_LABEL)
    _require_in_range(total, _TOTAL_LABEL, MIN_TOTAL, MAX_TOTAL)
    _require_in_range(people, _PEOPLE_LABEL, MIN_PEOPLE, MAX_PEOPLE)

    per_person = total // people // ROUNDING_UNIT * ROUNDING_UNIT
    organizer_payment = total - per_person * (people - 1)
    return OrganizerPaysSplit(
        per_person=per_person, organizer_payment=organizer_payment
    )


def _require_int(value: object, label: str) -> None:
    # bool は int のサブクラスだが、True を 1 として黙って計算させないため拒否する
    if type(value) is not int:
        raise TypeError(f"{label}は整数で指定する: {value!r}")


def _require_in_range(value: int, label: str, minimum: int, maximum: int) -> None:
    if not minimum <= value <= maximum:
        raise ValueError(
            f"{label}は {minimum:,}〜{maximum:,} の範囲で指定する: {value}"
        )
