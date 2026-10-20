#!/usr/bin/env bash
# タスク記録（docs/project/tasks/TASK-xxx-*.md）を作成・更新する。更新規則は DOC-10〜13、WF-09・11。
# 使い方:
#   task.sh begin [--next <次の一手>] <ブランチ名|hotfix|-> <ファイル名> <タスク名> [関連ID ...]
#       作業ブランチに入り（- なら今のブランチのまま）、TASK を作って in-progress にし、起点のコミットを作業ログに書いてコミットする（GIT-10 (1)）。
#       「現在のフェーズ」は「探索」、「次の一手」は --next の値（省くと「<タスク名> の探索を始める」）にする（DOC-14）
#   task.sh new <ファイル名（英語のケバブケース）> <タスク名> [関連ID ...]   新しい TASK を作り、パスを出力する（番号は全ブランチの最大＋1）。
#       「現在のフェーズ」は「未着手」、「次の一手」は関連 ID から決まる Skill（DES があれば /implement-tdd、REQ だけなら /plan-spec）にする
#   task.sh status <TASK-ID> <todo|in-progress|done|paused>               フロントマターの status を変える
#   task.sh phase <TASK-ID> <現在のフェーズ> <次の一手>                    2つのセクションを上書きする
#   task.sh log <TASK-ID> <フェーズ> <行ったことと結果>                    作業ログに1行追記する（DOC-11）
#   task.sh freeze <TASK-ID> <テストファイルのパス>                         frozen_tests に追記する（TEST-04）
#   task.sh relate <TASK-ID> <ID>                                          related に REQ / DES の ID を追記する（WF-10）
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

# 作業ツリーと、手元・リモートのすべてのブランチにある TASK のファイル名を1行1件で返す。
# ブランチごとに TASK を作るため、他のブランチの番号と重ならないようにする（GIT-04、GIT-61）。
task_names() {
  local ref
  ls "$TASKS_DIR" 2>/dev/null || true
  git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || return 0
  git -C "$ROOT" for-each-ref --format='%(refname)' refs/heads refs/remotes | while IFS= read -r ref; do
    git -C "$ROOT" ls-tree --name-only "$ref" docs/project/tasks/ 2>/dev/null | sed 's|.*/||'
  done
}

cmd_new() {
  [ $# -ge 2 ] || fail "new <ファイル名> <タスク名> [関連ID ...]"
  local name="$1" title="$2"; shift 2
  case "$name" in *[!a-z0-9-]*|"") fail "ファイル名は英語のケバブケースにする（DOC-04）: $name" ;; esac
  [ -f "$TEMPLATE" ] || fail "テンプレート $TEMPLATE がない"
  mkdir -p "$TASKS_DIR"
  local last next related file
  last=$(task_names | sed -n 's/^TASK-\([0-9][0-9]*\)-.*\.md$/\1/p' | sort -n | tail -n 1)
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
  replace_section "$file" "## 現在のフェーズ" "未着手"
  replace_section "$file" "## 次の一手" "$(first_step_of "$title" "$@")"
  printf '%s\n' "${file#"$ROOT"/}"
}

# 関連 ID（$2 以降）から、TASK を始める Skill の最初の手順を DOC-14 の形で返す。$1 はタスク名。
# shellcheck disable=SC2016  # バッククォートは Markdown のコードの印
first_step_of() {
  local title="$1" id des="" req=""; shift
  for id in "$@"; do
    case "$id" in DES-[0-9]*) des=${des:-$id} ;; REQ-[0-9]*) req=${req:-$id} ;; esac
  done
  if [ -n "$des" ]; then
    printf '`/implement-tdd %s` の手順 1: 規則と対象の DES を読む' "$des"
  elif [ -n "$req" ]; then
    printf '`/plan-spec %s` の手順 1: 規則を読んで設計を始める' "$req"
  else
    printf '%s に着手する' "$title"
  fi
}

cmd_begin() {
  local next=""
  if [ "${1-}" = "--next" ]; then
    [ $# -ge 2 ] || fail "--next の後に次の一手を書く"
    next="$2"; shift 2
  fi
  [ $# -ge 3 ] || fail "begin [--next <次の一手>] <ブランチ名 | hotfix | -> <ファイル名> <タスク名> [関連ID ...]"
  local branch="$1" base file id; shift
  next=${next:-"$2 の探索を始める"}
  if [ "$branch" != "-" ]; then
    bash "$(dirname "$0")/branch.sh" start "$branch" >/dev/null || exit 1
  fi
  branch=$(git -C "$ROOT" symbolic-ref --quiet --short HEAD) || fail "ブランチ上にいない（detached HEAD）"
  case "$branch" in main|develop) fail "$branch では TASK を始めない。作業ブランチ（GIT-03）を指定する" ;; esac
  base=$(git -C "$ROOT" rev-parse --short=12 HEAD)
  file=$(cmd_new "$@") || exit 1
  id=$(basename "$file" | sed -n 's/^\(TASK-[0-9]*\)-.*/\1/p')
  cmd_status "$id" in-progress
  cmd_phase "$id" 探索 "$next"
  cmd_log "$id" 開始 "起点のコミット $base"
  git -C "$ROOT" add "$file"
  git -C "$ROOT" commit --quiet -m "chore($id): TASK を作成" -m "Refs: $id"
  printf 'TASK: %s\nブランチ: %s\n起点のコミット: %s\n' "$file" "$branch" "$base"
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

[ $# -ge 1 ] || fail "サブコマンド（begin / new / status / phase / log / freeze / relate）を指定する"
sub="$1"; shift
case "$sub" in
  begin) cmd_begin "$@" ;;
  new) cmd_new "$@" ;;
  status) cmd_status "$@" ;;
  phase) cmd_phase "$@" ;;
  log) cmd_log "$@" ;;
  freeze) cmd_freeze "$@" ;;
  relate) cmd_relate "$@" ;;
  *) fail "不明なサブコマンド: $sub" ;;
esac
