import argparse
import sys
from dataclasses import dataclass
from typing import NoReturn

from warikan.calc import split_collect_extra, split_organizer_pays

_METHOD_ORGANIZER_PAYS = "organizer-pays"
_METHOD_COLLECT_EXTRA = "collect-extra"
_METHODS = (_METHOD_ORGANIZER_PAYS, _METHOD_COLLECT_EXTRA)
_METHOD_METAVAR = "{" + ",".join(_METHODS) + "}"

# int() は 4300 桁を超える文字列を変換できないため、変換前に長さを制限する
_MAX_NUMBER_LENGTH = 20

_TOTAL_LABEL = "合計金額"
_PEOPLE_LABEL = "人数"


class _InputError(Exception):
    pass


class _Parser(argparse.ArgumentParser):
    def error(self, message: str) -> NoReturn:
        raise _InputError(f"コマンドライン引数が正しくない: {message}")


@dataclass(frozen=True)
class _Request:
    total: int
    people: int
    method: str


def main(argv: list[str] | None = None) -> int:
    try:
        request = _parse_request(argv)
        lines = _result_lines(request)
    except (_InputError, ValueError) as error:
        print(f"エラー: {error}", file=sys.stderr)
        return 1

    for line in lines:
        print(line)
    return 0


def _parse_request(argv: list[str] | None) -> _Request:
    args, extras = _build_parser().parse_known_intermixed_args(argv)
    _reject_extras(extras)
    total_text = _require_given(args.total, _TOTAL_LABEL)
    people_text = _require_given(args.people, _PEOPLE_LABEL)

    total = _parse_number(total_text, _TOTAL_LABEL)
    people = _parse_number(people_text, _PEOPLE_LABEL)
    _require_known_method(args.method)
    return _Request(total=total, people=people, method=args.method)


def _build_parser() -> argparse.ArgumentParser:
    # 位置引数を省略可能にしているため、必須に見える使い方の表示を自分で組み立てる
    parser = _Parser(
        prog="warikan",
        usage=f"%(prog)s [-h] total people [--method {_METHOD_METAVAR}]",
        allow_abbrev=False,
    )
    parser.add_argument("total", nargs="?")
    parser.add_argument("people", nargs="?")
    parser.add_argument(
        "--method", default=_METHOD_ORGANIZER_PAYS, metavar=_METHOD_METAVAR
    )
    return parser


def _reject_extras(extras: list[str]) -> None:
    if not extras:
        return
    first = extras[0]
    if first.startswith("-"):
        raise _InputError(f"定義されていないオプションがある: {first!r}")
    raise _InputError(f"余分な引数がある: {first!r}")


def _require_given(text: str | None, label: str) -> str:
    if text is None:
        raise _InputError(f"{label}が指定されていない")
    return text


def _parse_number(text: str, label: str) -> int:
    if len(text) > _MAX_NUMBER_LENGTH:
        raise _InputError(
            f"{label}は{_MAX_NUMBER_LENGTH}文字以内の半角数字（整数）で指定する: "
            f"{len(text)}文字の入力"
        )
    # isdigit() だけでは全角数字や上付き数字も真になるため、isascii() と組み合わせる
    if not (text.isascii() and text.isdigit()):
        raise _InputError(f"{label}は半角数字の整数で指定する: {text!r}")
    return int(text)


def _require_known_method(method: str) -> None:
    if method in _METHODS:
        return
    raise _InputError(
        f"方式は {_METHOD_ORGANIZER_PAYS}（幹事負担）または "
        f"{_METHOD_COLLECT_EXTRA}（多めに集める）で指定する: {method!r}"
    )


def _result_lines(request: _Request) -> list[str]:
    if request.method == _METHOD_COLLECT_EXTRA:
        extra_split = split_collect_extra(request.total, request.people)
        return [
            f"1人あたり {_format_yen(extra_split.per_person)}",
            f"余り {_format_yen(extra_split.surplus)}",
        ]
    organizer_split = split_organizer_pays(request.total, request.people)
    return [
        f"1人あたり {_format_yen(organizer_split.per_person)}",
        f"幹事 {_format_yen(organizer_split.organizer_payment)}",
    ]


def _format_yen(amount: int) -> str:
    return f"{amount:,}円"
