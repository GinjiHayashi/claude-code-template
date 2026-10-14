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
