import argparse

from warikan.calc import split_collect_extra, split_organizer_pays

_METHOD_ORGANIZER_PAYS = "organizer-pays"
_METHOD_COLLECT_EXTRA = "collect-extra"


def main(argv: list[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)

    lines = _result_lines(args.method, int(args.total), int(args.people))

    for line in lines:
        print(line)
    return 0


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="warikan")
    parser.add_argument("total")
    parser.add_argument("people")
    parser.add_argument(
        "--method",
        choices=[_METHOD_ORGANIZER_PAYS, _METHOD_COLLECT_EXTRA],
        default=_METHOD_ORGANIZER_PAYS,
    )
    return parser


def _result_lines(method: str, total: int, people: int) -> list[str]:
    if method == _METHOD_COLLECT_EXTRA:
        extra_split = split_collect_extra(total, people)
        return [
            f"1人あたり {_format_yen(extra_split.per_person)}",
            f"余り {_format_yen(extra_split.surplus)}",
        ]
    organizer_split = split_organizer_pays(total, people)
    return [
        f"1人あたり {_format_yen(organizer_split.per_person)}",
        f"幹事 {_format_yen(organizer_split.organizer_payment)}",
    ]


def _format_yen(amount: int) -> str:
    return f"{amount:,}円"
