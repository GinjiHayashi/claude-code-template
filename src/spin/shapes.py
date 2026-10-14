"""図形の表面の点の生成と、選べる図形の一覧。"""

import math
from collections.abc import Callable
from types import MappingProxyType

from spin.rendering import BOUNDING_RADIUS, SurfacePoint, Vector3

type ShapeFactory = Callable[[], tuple[SurfacePoint, ...]]

_TUBE_STEPS = 60
_RING_STEPS = 200
_RING_RADIUS = BOUNDING_RADIUS * 2 / 3
_TUBE_RADIUS = BOUNDING_RADIUS / 3
_CUBE_STEPS = 60
# 角には点がないので、角に一番近いマスの中心 (±a, ±ak, ±ak) が外接球の上に来る a にする
_CUBE_HALF_SIDE = BOUNDING_RADIUS / math.sqrt(
    1 + 2 * ((_CUBE_STEPS - 1) / _CUBE_STEPS) ** 2
)
_MOBIUS_RADIUS = BOUNDING_RADIUS * 2 / 3
_MOBIUS_HALF_WIDTH = BOUNDING_RADIUS / 3
_MOBIUS_LENGTH_STEPS = 400
_MOBIUS_WIDTH_STEPS = 40


def _torus_point(theta: float, phi: float) -> SurfacePoint:
    """管の周りの角 theta と中心円の周りの角 phi にあるドーナツの表面の点を返す。"""
    cos_theta, sin_theta = math.cos(theta), math.sin(theta)
    cos_phi, sin_phi = math.cos(phi), math.sin(phi)
    distance_from_axis = _RING_RADIUS + _TUBE_RADIUS * cos_theta
    return SurfacePoint(
        position=(
            distance_from_axis * cos_phi,
            distance_from_axis * sin_phi,
            _TUBE_RADIUS * sin_theta,
        ),
        normal=(cos_theta * cos_phi, cos_theta * sin_phi, sin_theta),
    )


def torus() -> tuple[SurfacePoint, ...]:
    """z 軸を対称軸とするドーナツの表面の点を返す。"""
    return tuple(
        _torus_point(math.tau * i / _TUBE_STEPS, math.tau * j / _RING_STEPS)
        for i in range(_TUBE_STEPS)
        for j in range(_RING_STEPS)
    )


def _cube_point(axis: int, sign: float, u: float, v: float) -> SurfacePoint:
    """軸 axis に垂直で向きが sign の面の上で、残りの2軸の座標が u・v の点を返す。"""
    first, second = (i for i in range(3) if i != axis)
    position = {axis: sign * _CUBE_HALF_SIDE, first: u, second: v}
    normal = {axis: sign, first: 0.0, second: 0.0}
    return SurfacePoint(
        position=(position[0], position[1], position[2]),
        normal=(normal[0], normal[1], normal[2]),
    )


def cube() -> tuple[SurfacePoint, ...]:
    """中心が原点で各面が座標軸に垂直な立方体の表面の点を返す。"""
    # 辺の上に置くと2つの面の点が同じ位置で近さが等しくなるので、マスの中心だけを使う
    centers = [
        _CUBE_HALF_SIDE * (2 * i + 1 - _CUBE_STEPS) / _CUBE_STEPS
        for i in range(_CUBE_STEPS)
    ]
    return tuple(
        _cube_point(axis, sign, u, v)
        for axis in range(3)
        for sign in (-1.0, 1.0)
        for u in centers
        for v in centers
    )


def _unit_cross(left: Vector3, right: Vector3) -> Vector3:
    """2つの向きの外積を長さ 1 にして返す。"""
    cross = (
        left[1] * right[2] - left[2] * right[1],
        left[2] * right[0] - left[0] * right[2],
        left[0] * right[1] - left[1] * right[0],
    )
    length = math.hypot(*cross)
    return (cross[0] / length, cross[1] / length, cross[2] / length)


def mobius_strip_point(u: float, v: float) -> SurfacePoint:
    """中心線に沿う角 u、中心線からの距離 v にあるメビウスの帯の点を返す。"""
    cos_u, sin_u = math.cos(u), math.sin(u)
    cos_half, sin_half = math.cos(u / 2), math.sin(u / 2)
    distance_from_axis = _MOBIUS_RADIUS + v * cos_half
    # 面の向きは、位置を u で微分した向きと v で微分した向きの外積から求める
    along_u = (
        -v / 2 * sin_half * cos_u - distance_from_axis * sin_u,
        -v / 2 * sin_half * sin_u + distance_from_axis * cos_u,
        v / 2 * cos_half,
    )
    along_v = (cos_half * cos_u, cos_half * sin_u, sin_half)
    return SurfacePoint(
        position=(distance_from_axis * cos_u, distance_from_axis * sin_u, v * sin_half),
        normal=_unit_cross(along_u, along_v),
    )


def mobius_strip() -> tuple[SurfacePoint, ...]:
    """中心線が xy 平面の円で、1周で半回転ねじれたメビウスの帯の表面の点を返す。"""
    # 幅の向きは両端 ±w を含める。u = 0・v = w の点が外接球の上に来るため
    return tuple(
        mobius_strip_point(
            math.tau * j / _MOBIUS_LENGTH_STEPS,
            _MOBIUS_HALF_WIDTH * (2 * k / (_MOBIUS_WIDTH_STEPS - 1) - 1),
        )
        for j in range(_MOBIUS_LENGTH_STEPS)
        for k in range(_MOBIUS_WIDTH_STEPS)
    )


SHAPES: MappingProxyType[str, ShapeFactory] = MappingProxyType(
    {"torus": torus, "cube": cube, "mobius-strip": mobius_strip}
)
