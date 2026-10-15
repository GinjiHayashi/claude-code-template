#!/usr/bin/env bash
# SessionStart: 進行中の TASK の「現在のフェーズ」と「次の一手」を Claude に渡す。
set -u
. "$(dirname "$0")/lib.sh"

tasks=$(in_progress_tasks)
if [ -z "$tasks" ]; then
  echo "進行中・中断中の TASK はない。ユーザーに次の作業を確認する。"
  exit 0
fi

echo "進行中・中断中の TASK がある。「次の一手」から再開する（中断中は再開してよいかユーザーに確認する）。"
while IFS= read -r task; do
  echo
  echo "## $(to_relative "$task")（status: $(front_matter_value "$task" status)）"
  awk '
    /^## / { show = ($0 == "## 現在のフェーズ" || $0 == "## 次の一手") }
    show && !/^>/ && NF { print }
  ' "$task"
done <<< "$tasks"
exit 0
