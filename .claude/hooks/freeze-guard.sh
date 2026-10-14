#!/usr/bin/env bash
# PreToolUse（Edit|Write）: 進行中 TASK の frozen_tests にあるファイルの編集を止める（TEST-04）。
set -u
. "$(dirname "$0")/lib.sh"

file=$(read_file_path)
[ -n "$file" ] || exit 0
target=$(to_relative "$file")

while IFS= read -r task; do
  while IFS= read -r frozen; do
    [ -n "$frozen" ] || continue
    if [ "$target" = "$(to_relative "$frozen")" ]; then
      printf '%s は %s で凍結されている（TEST-04）。テストを変えずに実装を直す。テストが誤っていると判断したら、作業を止めてユーザーに報告する（TEST-05）。\n' \
        "$target" "$(to_relative "$task")" >&2
      exit 2
    fi
  done < <(frozen_tests_of "$task")
done < <(in_progress_tasks)
exit 0
