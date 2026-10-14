#!/usr/bin/env bash
# タスク記録（docs/project/tasks/TASK-xxx-*.md）を作成・更新する。更新規則は DOC-10〜13、WF-08・09。
# 使い方:
#   task.sh new <ファイル名（英語のケバブケース）> <タスク名> [関連ID ...]   新しい TASK を作り、パスを出力する
#   task.sh status <TASK-ID> <todo|in-progress|done|paused>               フロントマターの status を変える
#   task.sh phase <TASK-ID> <現在のフェーズ> <次の一手>                    2つのセクションを上書きする
#   task.sh log <TASK-ID> <フェーズ> <行ったことと結果>                    作業ログに1行追記する（DOC-11）
#   task.sh freeze <TASK-ID> <テストファイルのパス>                         frozen_tests に追記する（TEST-04）
#   task.sh relate <TASK-ID> <ID>                                          related に REQ / DES の ID を追記する（WF-20）
set -eu

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
TASKS_DIR="$ROOT/docs/project/tasks"
TEMPLATE="$ROOT/docs/guidelines/templates/task.md"
TODAY=$(date +%Y-%m-%d)

fail() { printf 'task.sh: %s\n' "$1" >&2; exit 1; }

# TASK-ID（例: TASK-003）からファイルを探す。
task_file() {
  local found
  found=$(ls "$TASKS_DIR"/"$1"-*.md 2>/dev/null | head -n 1)
  [ -n "$found" ] || fail "$1 のファイルが $TASKS_DIR にない"
  printf '%s' "$found"
}

# awk の出力で元のファイルを置き換え、updated を今日にする。
rewrite() {
  local file="$1"; shift
  local tmp="$file.tmp.$$"
  awk "$@" "$file" > "$tmp" && mv "$tmp" "$file"
  awk -v today="$TODAY" '
    NR == 1 && $0 == "---" { inside = 1 }
    inside && NR > 1 && $0 == "---" { inside = 0 }
    inside && /^updated:/ { sub(/^updated:[ \t]*[^ \t#]*/, "updated: " today) }
    { print }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# 見出し $2 のセクション本文（> の説明行を除く）を $3 で置き換える。
replace_section() {
  rewrite "$1" -v heading="$2" -v body="$3" '
    $0 == heading { print; skipping = 1; next }
    skipping && /^## / { print ""; print body; print ""; skipping = 0 }
    skipping && /^>/ { print; next }
    skipping { next }
    { print }
    END { if (skipping) { print ""; print body } }
  '
}

cmd_new() {
  [ $# -ge 2 ] || fail "new <ファイル名> <タスク名> [関連ID ...]"
  local name="$1" title="$2"; shift 2
  case "$name" in *[!a-z0-9-]*|"") fail "ファイル名は英語のケバブケースにする（DOC-04）: $name" ;; esac
  [ -f "$TEMPLATE" ] || fail "テンプレート $TEMPLATE がない"
  mkdir -p "$TASKS_DIR"
  local last next related file
  last=$(ls "$TASKS_DIR" 2>/dev/null | sed -n 's/^TASK-\([0-9][0-9]*\)-.*\.md$/\1/p' | sort -n | tail -n 1)
  next=$(printf '%03d' $(( 10#${last:-0} + 1 )))
  related=$(printf '%s, ' "$@"); related="[${related%, }]"
  [ $# -gt 0 ] || related="[]"
  file="$TASKS_DIR/TASK-$next-$name.md"
  awk -v id="TASK-$next" -v title="$title" -v related="$related" '
    /^related:/ { sub(/^related:[ \t]*\[[^]]*\]/, "related: " related) }
    /^# TASK-000 / { $0 = "# " id " " title }
    { print }
  ' "$TEMPLATE" > "$file"
  rewrite "$file" '{ print }'
  printf '%s\n' "${file#"$ROOT"/}"
}

cmd_status() {
  [ $# -eq 2 ] || fail "status <TASK-ID> <todo|in-progress|done|paused>"
  case "$2" in todo|in-progress|done|paused) ;; *) fail "status は todo / in-progress / done / paused のどれか（DOC-08）: $2" ;; esac
  rewrite "$(task_file "$1")" -v value="$2" '
    NR == 1 && $0 == "---" { inside = 1 }
    inside && NR > 1 && $0 == "---" { inside = 0 }
    inside && /^status:/ { sub(/^status:[ \t]*[^ \t#]*/, "status: " value) }
    { print }
  '
}

cmd_phase() {
  [ $# -eq 3 ] || fail "phase <TASK-ID> <現在のフェーズ> <次の一手>"
  local file; file=$(task_file "$1")
  replace_section "$file" "## 現在のフェーズ" "$2"
  replace_section "$file" "## 次の一手" "$3"
}

cmd_log() {
  [ $# -eq 3 ] || fail "log <TASK-ID> <フェーズ> <行ったことと結果>"
  local file; file=$(task_file "$1")
  # テンプレートの記入例の行は、最初の記録で取り除く。
  rewrite "$file" '!/^- YYYY-MM-DD / { print }'
  printf -- '- %s %s: %s\n' "$TODAY" "$2" "$3" >> "$file"
}

cmd_freeze() {
  [ $# -eq 2 ] || fail "freeze <TASK-ID> <テストファイルのパス>"
  local path="${2#"$ROOT"/}" file
  file=$(task_file "$1")
  grep -q '^frozen_tests:' "$file" || fail "$1 のフロントマターに frozen_tests がない"
  # 登録済みなら何もしない。
  awk -v path="$path" '
    /^frozen_tests:/ { listing = 1; next }
    listing && /^[ \t]*-[ \t]+/ { item = $0; sub(/^[ \t]*-[ \t]+/, "", item); gsub(/["\047]/, "", item); if (item == path) found = 1; next }
    listing { exit }
    END { exit !found }
  ' "$file" && return 0
  # 一覧の最後の項目の後ろに足す。
  rewrite "$file" -v path="$path" '
    listing && !/^[ \t]*-[ \t]+/ { print "  - " path; listing = 0 }
    /^frozen_tests:/ { listing = 1 }
    { print }
  '
}

cmd_relate() {
  [ $# -eq 2 ] || fail "relate <TASK-ID> <ID>"
  case "$2" in REQ-[0-9]*|DES-[0-9]*) ;; *) fail "ID は REQ-xxx か DES-xxx: $2" ;; esac
  rewrite "$(task_file "$1")" -v id="$2" '
    NR == 1 && $0 == "---" { inside = 1 }
    inside && NR > 1 && $0 == "---" { inside = 0 }
    inside && /^related:/ && index($0, id) == 0 {
      if ($0 ~ /\[[ \t]*\]/) sub(/\[[ \t]*\]/, "[" id "]")
      else sub(/\]/, ", " id "]")
    }
    { print }
  '
}

[ $# -ge 1 ] || fail "サブコマンド（new / status / phase / log / freeze / relate）を指定する"
sub="$1"; shift
case "$sub" in
  new) cmd_new "$@" ;;
  status) cmd_status "$@" ;;
  phase) cmd_phase "$@" ;;
  log) cmd_log "$@" ;;
  freeze) cmd_freeze "$@" ;;
  relate) cmd_relate "$@" ;;
  *) fail "不明なサブコマンド: $sub" ;;
esac
