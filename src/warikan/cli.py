import argparse

from warikan.calc import split_organizer_pays

_METHOD_ORGANIZER_PAYS = "organizer-pays"


def main(argv: list[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)

    split = split_organizer_pays(int(args.total), int(args.people))

    print(f"1人あたり {_format_yen(split.per_person)}")
    print(f"幹事 {_format_yen(split.organizer_payment)}")
    return 0


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="warikan")
    parser.add_argument("total")
    parser.add_argument("people")
    parser.add_argument(
        "--method",
        choices=[_METHOD_ORGANIZER_PAYS],
        default=_METHOD_ORGANIZER_PAYS,
    )
    return parser


def _format_yen(amount: int) -> str:
    return f"{amount:,}円"
