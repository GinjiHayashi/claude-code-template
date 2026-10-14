"""描画計算。表面の点の回転・投影・明るさから1フレームの文字列を作る。"""

import math
from collections.abc import Sequence
from dataclasses import dataclass

type Vector3 = tuple[float, float, float]

BOUNDING_RADIUS = 1.0
SHADE_CHARS = ".,-~:;=!*#$@"
LIGHT_DIRECTION: Vector3 = (0.0, 1 / math.sqrt(2), -1 / math.sqrt(2))

_VIEWPOINT_DISTANCE = 5.0
_VIEWPOINT: Vector3 = (0.0, 0.0, -_VIEWPOINT_DISTANCE)
_FILL_RATIO = 0.9
_CHAR_ASPECT = 2.0
# 外接球の中の点を投影したときの、近さを掛けた座標の最大の傾き（外接球の接線の傾き）
_TANGENT_SLOPE = BOUNDING_RADIUS / math.sqrt(
    _VIEWPOINT_DISTANCE**2 - BOUNDING_RADIUS**2
)
_BLANK = " "


@dataclass(frozen=True)
class SurfacePoint:
    """図形の表面の点。位置と、長さ 1 の面の向きを持つ。"""

    position: Vector3
    normal: Vector3


@dataclass(frozen=True)
class Rotation:
    """回転角の組（ラジアン）。x 軸の周りの角と z 軸の周りの角。"""

    x_angle: float
    z_angle: float


def _dot(a: Vector3, b: Vector3) -> float:
    """2つの向きの内積を返す。"""
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def _rotate_vector(
    vector: Vector3, trigonometry: tuple[float, float, float, float]
) -> Vector3:
    """向きを x 軸、z 軸の周りの順に回す。値は (cos x, sin x, cos z, sin z)。"""
    cos_x, sin_x, cos_z, sin_z = trigonometry
    x, y, z = vector
    y, z = y * cos_x - z * sin_x, y * sin_x + z * cos_x
    return (x * cos_z - y * sin_z, x * sin_z + y * cos_z, z)


def _trigonometry(rotation: Rotation) -> tuple[float, float, float, float]:
    """回転角から (cos x, sin x, cos z, sin z) を返す。"""
    # 2π で割った余りにして、回転角 2π が 0 と完全に同じ計算になるようにする
    x_angle = rotation.x_angle % math.tau
    z_angle = rotation.z_angle % math.tau
    return (math.cos(x_angle), math.sin(x_angle), math.cos(z_angle), math.sin(z_angle))


def rotate(point: SurfacePoint, rotation: Rotation) -> SurfacePoint:
    """点の位置と面の向きを、x 軸の周り、z 軸の周りの順に回転した点を返す。"""
    trigonometry = _trigonometry(rotation)
    return SurfacePoint(
        position=_rotate_vector(point.position, trigonometry),
        normal=_rotate_vector(point.normal, trigonometry),
    )


def project(position: Vector3, width: int, height: int) -> tuple[int, int, float]:
    """回転後の位置を透視投影し、(行, 列, 近さ) を返す。画面の外でもそのまま返す。"""
    x, y, z = position
    closeness = 1 / (z + _VIEWPOINT_DISTANCE)
    half_extent = _FILL_RATIO * min(height / 2, width / 2 / _CHAR_ASPECT)
    scale_y = half_extent / _TANGENT_SLOPE
    scale_x = _CHAR_ASPECT * scale_y
    col = math.floor(width / 2 + scale_x * x * closeness)
    row = math.floor(height / 2 - scale_y * y * closeness)
    return row, col, closeness


def shade(point: SurfacePoint) -> str:
    """視点の側にそろえた面の向きが光源に向く度合いに応じて、明るさの文字を返す。"""
    # 表裏の区別がない面も同じ規則で描けるよう、面の向きを視点の側にそろえる
    x, y, z = point.position
    to_viewpoint: Vector3 = (_VIEWPOINT[0] - x, _VIEWPOINT[1] - y, _VIEWPOINT[2] - z)
    normal = point.normal
    if _dot(normal, to_viewpoint) < 0:
        normal = (-normal[0], -normal[1], -normal[2])

    # 光源に向いている度合いを明るさの文字に割り当てる
    luminance = _dot(normal, LIGHT_DIRECTION)
    if luminance <= 0:
        return SHADE_CHARS[0]
    last = len(SHADE_CHARS) - 1
    return SHADE_CHARS[min(math.floor(luminance * len(SHADE_CHARS)), last)]


def render_frame(
    points: Sequence[SurfacePoint], rotation: Rotation, width: int, height: int
) -> str:
    """表面の点から1フレームの文字列を作る。幅・高さが 1 未満なら ValueError。"""
    # 入力の検証
    if width < 1:
        raise ValueError(f"width は 1 以上にする: width={width}")
    if height < 1:
        raise ValueError(f"height は 1 以上にする: height={height}")

    grid = [[_BLANK] * width for _ in range(height)]
    depth_buffer = [[0.0] * width for _ in range(height)]

    # 各マスに、一番手前の点の明るさの文字を置く
    for point in points:
        rotated = rotate(point, rotation)
        row, col, closeness = project(rotated.position, width, height)
        if not (0 <= row < height and 0 <= col < width):
            continue
        if closeness > depth_buffer[row][col]:
            depth_buffer[row][col] = closeness
            grid[row][col] = shade(rotated)

    return "\n".join("".join(line) for line in grid)
