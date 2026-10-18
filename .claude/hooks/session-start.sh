#!/usr/bin/env bash
# SessionStart: 進行中の TASK の「現在のフェーズ」と「次の一手」を Claude に渡す。
set -u
. "$(dirname "$0")/lib.sh"

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
