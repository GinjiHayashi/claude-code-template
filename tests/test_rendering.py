"""spin.rendering のテスト（DES-001）。合成した表面の点で描画計算を確かめる。"""

import dataclasses
import math

import pytest

from spin import rendering
from spin.rendering import Rotation, SurfacePoint, project, render_frame, rotate, shade

S = 1 / math.sqrt(2)
LIGHT = (0.0, S, -S)
# 光源と直交し、視点の側（z が負）を向く長さ 1 の向き
FACING_PERPENDICULAR = (0.0, -S, -S)


def _combine(a: float, u: tuple, b: float, v: tuple) -> tuple:
    return tuple(a * p + b * q for p, q in zip(u, v, strict=True))


def _at_origin(normal: tuple) -> SurfacePoint:
    return SurfacePoint(position=(0.0, 0.0, 0.0), normal=normal)


def _assert_vector_close(actual: tuple, expected: tuple) -> None:
    for a, e in zip(actual, expected, strict=True):
        assert math.isclose(a, e, abs_tol=1e-9), (actual, expected)


@pytest.mark.parametrize(
    "width, height, name, value",
    [
        pytest.param(0, 24, "width", "0", id="DES-001#4 幅0"),
        pytest.param(80, 0, "height", "0", id="DES-001#4 高さ0"),
        pytest.param(-1, 24, "width", "-1", id="DES-001#4 幅-1"),
    ],
)
def test_render_frame_rejects_non_positive_size(width, height, name, value):
    """DES-001 #4 幅か高さが 1 未満なら、引数名と値を含む ValueError を出す。"""
    with pytest.raises(ValueError) as error:
        render_frame((), Rotation(0.0, 0.0), width, height)

    assert name in str(error.value)
    assert value in str(error.value)


def test_render_frame_without_points_is_all_blank():
    """DES-001 #5 表面の点が空なら、24 行・各行 80 個の空白になる。"""
    frame = render_frame((), Rotation(0.0, 0.0), 80, 24)

    assert frame == "\n".join([" " * 80] * 24)


def test_projected_horizontal_span_is_twice_vertical_span():
    """DES-001 #12 外接球の直径の線分は、横が縦の 2 倍（±1）のマスを占める。"""
    steps = [-1 + 2 * i / 1000 for i in range(1001)]

    cols = {project((t, 0.0, 0.0), 80, 24)[1] for t in steps}
    rows = {project((0.0, t, 0.0), 80, 24)[0] for t in steps}

    assert abs(len(cols) - 2 * len(rows)) <= 1


def test_project_maps_origin_to_screen_center():
    """DES-001 #13 原点は行 12・列 40、近さ 1/5 に投影される。"""
    row, col, closeness = project((0.0, 0.0, 0.0), 80, 24)

    assert (row, col) == (12, 40)
    assert closeness == pytest.approx(1 / 5)


@pytest.mark.parametrize(
    "near_first",
    [
        pytest.param(True, id="DES-001#14 近い点が先"),
        pytest.param(False, id="DES-001#14 遠い点が先"),
    ],
)
def test_render_frame_draws_nearer_point_in_shared_cell(near_first):
    """DES-001 #14 同じマスの2点では、並びの順によらず視点に近い点の文字を描く。"""
    near = SurfacePoint(position=(0.0, 0.0, -0.5), normal=LIGHT)
    far = SurfacePoint(position=(0.0, 0.0, 0.5), normal=(0.0, 0.0, -1.0))
    points = (near, far) if near_first else (far, near)

    frame = render_frame(points, Rotation(0.0, 0.0), 80, 24)

    assert frame.split("\n")[12][40] == "@"


def test_shade_point_facing_light_is_brightest():
    """DES-001 #15 面の向きが光源と一致する点は @ になる。"""
    assert shade(_at_origin(LIGHT)) == "@"


def test_shade_point_at_sixty_degrees_is_between_darkest_and_brightest():
    """DES-001 #16 光源となす角が 60 度の点は、. と @ の間の文字になる。"""
    normal = _combine(0.5, LIGHT, math.sqrt(3) / 2, FACING_PERPENDICULAR)

    char = shade(_at_origin(normal))

    assert char in rendering.SHADE_CHARS[1:-1]


@pytest.mark.parametrize(
    "normal",
    [
        pytest.param(FACING_PERPENDICULAR, id="DES-001#17 90度"),
        pytest.param(
            _combine(-0.5, LIGHT, math.sqrt(3) / 2, FACING_PERPENDICULAR),
            id="DES-001#17 120度",
        ),
    ],
)
def test_shade_point_turned_away_from_light_is_darkest(normal):
    """DES-001 #17 光源となす角が 90 度以上の点は . になる。"""
    assert shade(_at_origin(normal)) == "."


def test_shade_flips_normal_facing_away_from_viewpoint():
    """DES-001 #18 視点と反対を向く面の向きは反転してから明るさを求める。"""
    away = _at_origin((0.0, -S, S))
    toward = _at_origin(LIGHT)

    assert shade(away) == "@"
    assert shade(toward) == "@"


def test_shade_keeps_normal_perpendicular_to_viewpoint():
    """DES-001 #19 視点への向きと直交する面の向きは反転しない。"""
    assert shade(_at_origin((0.0, -1.0, 0.0))) == "."


@pytest.mark.parametrize(
    "rotation_angles, expected",
    [
        pytest.param((0.0, 0.0), (0.0, 1.0, 0.0), id="DES-001#20 回転なし"),
        pytest.param((math.pi / 2, 0.0), (0.0, 0.0, 1.0), id="DES-001#20 x軸"),
        pytest.param((0.0, math.pi / 2), (-1.0, 0.0, 0.0), id="DES-001#20 z軸"),
    ],
)
def test_rotate_turns_position_and_normal(rotation_angles, expected):
    """DES-001 #20 位置と面の向きの両方を、x 軸、z 軸の順に回転する。"""
    point = SurfacePoint(position=(0.0, 1.0, 0.0), normal=(0.0, 1.0, 0.0))

    rotated = rotate(point, Rotation(*rotation_angles))

    _assert_vector_close(rotated.position, expected)
    _assert_vector_close(rotated.normal, expected)


def test_rotate_by_full_turn_equals_no_rotation_exactly():
    """DES-001 #21 回転角 2π と 0 の結果は完全に一致する（設計の判断で == を使う）。"""
    length = math.sqrt(0.2**2 + 0.4**2 + 0.8**2)
    point = SurfacePoint(
        position=(0.3, -0.2, 0.5),
        normal=(0.2 / length, 0.4 / length, -0.8 / length),
    )

    full_turn = rotate(point, Rotation(2 * math.pi, 2 * math.pi))
    no_turn = rotate(point, Rotation(0.0, 0.0))

    assert full_turn == no_turn


def test_surface_point_and_rotation_are_immutable():
    """DES-001 #27 SurfacePoint と Rotation の属性には代入できない。"""
    point = SurfacePoint(position=(0.0, 0.0, 0.0), normal=(0.0, 0.0, -1.0))
    rotation = Rotation(0.0, 0.0)

    with pytest.raises(dataclasses.FrozenInstanceError):
        point.position = (1.0, 0.0, 0.0)
    with pytest.raises(dataclasses.FrozenInstanceError):
        rotation.x_angle = 1.0


def test_shade_chars_match_glossary():
    """DES-001 #28 明るさの文字は glossary.md と同じ12文字・同じ順である。"""
    assert rendering.SHADE_CHARS == ".,-~:;=!*#$@"
