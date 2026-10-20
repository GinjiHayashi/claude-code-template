#!/usr/bin/env bash
# SessionStart: 進行中の TASK の「現在のフェーズ」と「次の一手」を Claude に渡す。
# 進行中の TASK がなければ、次の作業の手がかり（todo の TASK か、最後に done になった TASK の「次の一手」）を渡す。
set -u
. "$(dirname "$0")/lib.sh"

# 次の作業の手がかりを1行で出力する。「次の一手」が書かれた todo の TASK（番号の小さい順）を優先し、
# なければ最後に done になった TASK（番号の最も大きいもの）の「次の一手」を使う。
# TASK のファイル名には空白を含めない（task.sh が作る）ため、空白区切りで持つ。
print_next_hint() {
  local task status todo="" done_task="" next
  [ -d "$TASKS_DIR" ] || return 0
  for task in "$TASKS_DIR"/TASK-*.md; do
    [ -f "$task" ] || continue
    status=$(front_matter_value "$task" status)
    if [ "$status" = "todo" ]; then todo="$todo $task"; fi
    if [ "$status" = "done" ]; then done_task="$task"; fi
  done
  for task in $todo $done_task; do
    next=$(section_of "$task" "## 次の一手" | paste -sd ' ' -)
    case "$next" in ""|"（未記入）"*|"（なし）"*) continue ;; esac
    printf '次の作業の手がかり: %s（status: %s）の「次の一手」: %s\n' \
      "$(to_relative "$task")" "$(front_matter_value "$task" status)" "$next"
    echo "/progress（WF-23）で次の作業を確かめ、ユーザーに確認してから始める。"
    return 0
  done
}

tasks=$(in_progress_tasks)
if [ -z "$tasks" ]; then
  # TASK は作業ブランチにあるため、main / develop にいると見えない（GIT-03）。
  branch=$(git -C "$ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null || true)
  case "$branch" in
    main|develop)
      others=$(git -C "$ROOT" for-each-ref --format='%(refname:short)' --no-merged "$branch" refs/heads/feature refs/heads/hotfix refs/remotes/origin/feature refs/remotes/origin/hotfix 2>/dev/null | sed 's|^origin/||' | sort -u || true)
      if [ -n "$others" ]; then
        echo "現在は $branch にいる。$branch にマージしていない作業ブランチがあり、進行中の TASK はそちらにある可能性がある。ユーザーに伝え、続ける場合は bash .claude/scripts/branch.sh start <ブランチ名> で切り替えてから再開する。"
        printf '%s\n' "$others" | sed 's/^/- /'
        exit 0
      fi
      ;;
  esac
  echo "進行中・中断中の TASK はない。ユーザーに次の作業を確認する。"
  print_next_hint
  exit 0
fi

echo "進行中・中断中の TASK がある。「次の一手」から再開する（中断中は再開してよいかユーザーに確認する）。"
while IFS= read -r task; do
  echo
  echo "## $(to_relative "$task")（status: $(front_matter_value "$task" status)）"
  for heading in "## 現在のフェーズ" "## 次の一手"; do
    echo "$heading"
    section_of "$task" "$heading"
  done
done <<< "$tasks"
exit 0
