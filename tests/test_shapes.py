"""spin.shapes のテスト（DES-001）。選べるすべての図形で描画の基準を確かめる。"""

import math
from functools import cache

import pytest

from spin import rendering, shapes
from spin.rendering import Rotation, SurfacePoint, project, render_frame, rotate

SIZES = ((80, 24), (40, 10), (20, 40))


@cache
def _shape_points() -> dict[str, tuple[SurfacePoint, ...]]:
    return {name: factory() for name, factory in shapes.SHAPES.items()}


def _sixteen_rotations() -> list[Rotation]:
    # REQ-001 の受け入れ基準の前文の「16 通りの回転角」
    return [Rotation(2 * math.pi * k / 16, 2 * math.pi * k / 16) for k in range(16)]


def _allowed_chars() -> set[str]:
    return set(" " + rendering.SHADE_CHARS)


@pytest.mark.parametrize(
    "width, height",
    [
        pytest.param(80, 24, id="DES-001#1 幅80高さ24"),
        pytest.param(40, 10, id="DES-001#2 幅40高さ10"),
    ],
)
def test_frame_has_requested_rows_and_columns(width, height):
    """DES-001 #1 #2 全図形で、フレームは高さの行数で、各行は幅の文字数になる。"""
    for name, points in _shape_points().items():
        lines = render_frame(points, Rotation(0.0, 0.0), width, height).split("\n")

        assert len(lines) == height, name
        assert all(len(line) == width for line in lines), name


def test_torus_frame_of_single_cell():
    """DES-001 #3 幅 1・高さ 1 では、1 文字で、空白か明るさの文字になる。"""
    frame = render_frame(_shape_points()["torus"], Rotation(0.0, 0.0), 1, 1)

    assert len(frame) == 1
    assert frame in _allowed_chars()


def test_frame_uses_only_blank_and_shade_chars():
    """DES-001 #6 全図形・16 通りの回転角で、空白と明るさの文字だけを使う。"""
    for name, points in _shape_points().items():
        for rotation in _sixteen_rotations():
            chars = set(render_frame(points, rotation, 80, 24).replace("\n", ""))

            assert chars <= _allowed_chars(), (name, rotation)
            assert chars - {" "}, (name, rotation)


def test_frame_after_full_turn_matches_initial_frame():
    """DES-001 #7 全図形で、回転角 (0, 0) と (2π, 2π) のフレームが一致する。"""
    for name, points in _shape_points().items():
        initial = render_frame(points, Rotation(0.0, 0.0), 80, 24)
        full_turn = render_frame(points, Rotation(2 * math.pi, 2 * math.pi), 80, 24)

        assert initial == full_turn, name


def test_torus_frame_with_huge_rotation_angles():
    """DES-001 #8 極端な回転角でも、フレームの大きさと文字が正しい。"""
    frame = render_frame(_shape_points()["torus"], Rotation(1e9, -1e9), 80, 24)
    lines = frame.split("\n")

    assert len(lines) == 24
    assert all(len(line) == 80 for line in lines)
    assert set(frame.replace("\n", "")) <= _allowed_chars()


def test_farthest_point_lies_on_bounding_sphere():
    """DES-001 #9 全図形で、原点から一番遠い点の距離が外接球の半径に等しい。"""
    for name, points in _shape_points().items():
        farthest = max(math.hypot(*point.position) for point in points)

        assert math.isclose(farthest, rendering.BOUNDING_RADIUS, rel_tol=1e-9), name


def test_normals_have_unit_length():
    """DES-001 #10 全図形で、面の向きの長さが 1 である。"""
    for name, points in _shape_points().items():
        for point in points:
            assert math.isclose(math.hypot(*point.normal), 1.0, rel_tol=1e-9), name


def test_all_points_project_inside_screen():
    """DES-001 #11 全図形・3つの大きさ・16 通りの回転角で、全点が画面の内側に入る。"""
    for name, points in _shape_points().items():
        for width, height in SIZES:
            for rotation in _sixteen_rotations():
                for point in points:
                    position = rotate(point, rotation).position
                    row, col, _ = project(position, width, height)

                    assert 0 <= row < height, (name, width, height, rotation)
                    assert 0 <= col < width, (name, width, height, rotation)


def test_shapes_include_torus():
    """DES-001 #22 選べる図形にドーナツがあり、表面の点が1つ以上ある。"""
    assert "torus" in shapes.SHAPES
    assert len(shapes.SHAPES["torus"]()) > 0


def test_torus_hole_faces_viewpoint_at_zero_rotation():
    """DES-001 #23 回転角 (0, 0) のドーナツは、中央のマスが空白で、空白以外もある。"""
    frame = render_frame(_shape_points()["torus"], Rotation(0.0, 0.0), 80, 24)

    assert frame.split("\n")[12][40] == " "
    assert set(frame) - {" ", "\n"}


def test_shapes_cannot_be_modified():
    """DES-001 #24 選べる図形の一覧に新しいキーを代入すると TypeError になる。"""
    with pytest.raises(TypeError):
        shapes.SHAPES["cube"] = shapes.torus


def test_unknown_shape_name_raises_key_error():
    """DES-001 #25 選べる図形にない名前を引くと KeyError になる。"""
    with pytest.raises(KeyError):
        shapes.SHAPES["unknown"]


AXIS_DIRECTIONS = (
    (-1.0, 0.0, 0.0),
    (1.0, 0.0, 0.0),
    (0.0, -1.0, 0.0),
    (0.0, 1.0, 0.0),
    (0.0, 0.0, -1.0),
    (0.0, 0.0, 1.0),
)


def _matching_axis_direction(normal: tuple[float, float, float]) -> int | None:
    """normal と一致する AXIS_DIRECTIONS の添字を返す。どれとも違えば None。"""
    for index, direction in enumerate(AXIS_DIRECTIONS):
        if all(
            math.isclose(n, d, abs_tol=1e-9)
            for n, d in zip(normal, direction, strict=True)
        ):
            return index
    return None


def test_shapes_include_cube():
    """DES-006 #1 選べる図形に立方体が加わり、ドーナツも残っている。"""
    assert shapes.SHAPES.get("cube") is shapes.cube
    assert "torus" in shapes.SHAPES


def test_cube_points_lie_on_six_faces():
    """DES-006 #5 立方体の点は6つの面の上にあり、面の向きは外向きの軸の向きである。"""
    points = shapes.cube()
    counts = [0] * len(AXIS_DIRECTIONS)
    distances = []

    for point in points:
        index = _matching_axis_direction(point.normal)
        assert index is not None, point
        counts[index] += 1
        axis = index // 2
        along_normal = point.position[axis]
        assert along_normal * point.normal[axis] > 0, point
        distances.append(abs(along_normal))
        others = [abs(point.position[i]) for i in range(3) if i != axis]
        assert all(other < abs(along_normal) for other in others), point

    assert counts == [3600] * 6
    assert all(math.isclose(d, distances[0], rel_tol=1e-9) for d in distances)


def test_cube_point_count_is_within_limit():
    """DES-006 #6 立方体の点の数は 21600 で、DES-002 の上限 30000 以下である。"""
    count = len(shapes.cube())

    assert count == 21600
    assert count <= 30000


def test_cube_front_face_draws_single_shade_char():
    """DES-006 #7 回転角 (0, 0) の立方体は、空白以外のマスがすべて * になる。"""
    frame = render_frame(shapes.cube(), Rotation(0.0, 0.0), 80, 24)

    assert set(frame) - {" ", "\n"} == {"*"}


def _vectors_close(actual: tuple[float, ...], expected: tuple[float, ...]) -> bool:
    """2つの向きの各成分が絶対誤差 1e-9 で等しいかを返す。"""
    return all(
        math.isclose(a, e, abs_tol=1e-9) for a, e in zip(actual, expected, strict=True)
    )


def _dot(left: tuple[float, ...], right: tuple[float, ...]) -> float:
    """2つの向きの内積を返す。"""
    return sum(a * b for a, b in zip(left, right, strict=True))


def test_shapes_include_mobius_strip():
    """DES-007 #1 選べる図形にメビウスの帯が加わり、ドーナツと立方体も残っている。"""
    assert shapes.SHAPES.get("mobius-strip") is shapes.mobius_strip
    assert "torus" in shapes.SHAPES
    assert "cube" in shapes.SHAPES


def test_mobius_strip_normal_reverses_after_one_turn():
    """DES-007 #5 中心線を1周すると同じ位置に戻り、面の向きが −1 倍になる。"""
    start = shapes.mobius_strip_point(0.0, 0.0)
    end = shapes.mobius_strip_point(2 * math.pi, 0.0)

    assert _vectors_close(end.position, start.position)
    assert _vectors_close(end.normal, tuple(-n for n in start.normal))
    assert _vectors_close(start.normal, (0.0, 0.0, -1.0))


def test_mobius_strip_normal_changes_continuously_along_center_line():
    """DES-007 #6 中心線に沿って1周する間、隣り合う面の向きの内積が 0.99 より大きい。"""
    normals = [
        shapes.mobius_strip_point(2 * math.pi * j / 1000, 0.0).normal
        for j in range(1001)
    ]

    for previous, current in zip(normals, normals[1:], strict=False):
        assert _dot(previous, current) > 0.99


def test_mobius_strip_points_lie_on_strip():
    """DES-007 #7 帯の点は中心線の円から 1/3 以内で、面の向きは帯の幅の向きに垂直。"""
    for point in shapes.mobius_strip():
        x, y, z = point.position
        distance = math.hypot(math.hypot(x, y) - 2 / 3, z)
        u = math.atan2(y, x)
        width_direction = (
            math.cos(u / 2) * math.cos(u),
            math.cos(u / 2) * math.sin(u),
            math.sin(u / 2),
        )

        assert distance <= 1 / 3 + 1e-9, point
        assert math.isclose(_dot(point.normal, width_direction), 0.0, abs_tol=1e-9)


def test_mobius_strip_point_count_is_within_limit():
    """DES-007 #8 メビウスの帯の点の数は 16000 で、DES-002 の上限 30000 以下である。"""
    count = len(shapes.mobius_strip())

    assert count == 16000
    assert count <= 30000


@pytest.mark.parametrize(
    "v, position, normal",
    [
        pytest.param(
            1 / 3,
            (1.0, 0.0, 0.0),
            (0.0, 1 / math.sqrt(37), -6 / math.sqrt(37)),
            id="DES-007#9 v の最大値",
        ),
        pytest.param(
            -1 / 3,
            (1 / 3, 0.0, 0.0),
            (0.0, -1 / math.sqrt(5), -2 / math.sqrt(5)),
            id="DES-007#9 v の最小値",
        ),
    ],
)
def test_mobius_strip_point_at_strip_edges(v, position, normal):
    """DES-007 #9 帯の幅の両端の点の位置と面の向き。"""
    point = shapes.mobius_strip_point(0.0, v)

    assert _vectors_close(point.position, position)
    assert _vectors_close(point.normal, normal)
