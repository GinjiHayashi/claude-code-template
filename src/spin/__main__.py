"""python -m spin の入口。起動オプションの解析、図形の点の生成、再生をつなぐ。"""

import sys

from spin.animation import play, system_playback_environment
from spin.cli import parse_launch_options
from spin.shapes import SHAPES

options = parse_launch_options(sys.argv[1:])
play(SHAPES[options.shape_name](), options, system_playback_environment())
