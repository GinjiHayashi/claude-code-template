#!/usr/bin/env bash
# 計画書（docs/project/ の資料）のうち、機械で見つかる誤りを調べる（REV-15）。plan-reviewer に渡す前に実行し、指摘を0件にする。
# 調べること: フロントマター（status・updated・related。DOC-08）、（未記入）（DOC-18）、表の列数、
#   テンプレートの見出し（DOC-07）、test-items.md の項目番号の重複と欠番の再利用（TEST-11）、存在しない資料 ID の参照（DOC-01）。
# ファイルは変更しない。指摘は「パス:行: 内容（ルール ID）」で出力し、1件以上あれば終了コード 1 を返す。
# 使い方:
#   plan-lint.sh [資料のパス ...]   省くと docs/project/ のすべての資料を調べる
set -u
. "$(dirname "$0")/../hooks/lib.sh"

TEMPLATES_DIR="$ROOT/docs/guidelines/templates"
TODAY=$(date +%Y-%m-%d)

# 指摘を1行出力する。引数: 資料 行 内容
finding() {
  printf '%s:%s: %s\n' "$(to_relative "$1")" "$2" "$3"
}

# 資料の種類（TASK なら task）と、元のテンプレートのパス（なければ空）を「種類 テンプレート」で返す。
kind_of() {
  local relative name
  relative=$(to_relative "$1")
  name=$(basename "$1")
  case "$relative" in
    docs/project/tasks/TASK-*) printf 'task %s' "$TEMPLATES_DIR/task.md" ;;
    docs/project/requirements/REQ-*) printf 'document %s' "$TEMPLATES_DIR/requirement.md" ;;
    docs/project/design/DES-*) printf 'document %s' "$TEMPLATES_DIR/design.md" ;;
    docs/project/adr/ADR-*) printf 'document %s' "$TEMPLATES_DIR/adr.md" ;;
    docs/project/test-items.md|docs/project/*/*) printf 'document ' ;;
    *)
      if [ -f "$TEMPLATES_DIR/$name" ]; then printf 'document %s' "$TEMPLATES_DIR/$name"; else printf 'document '; fi ;;
  esac
}

# フロントマターの キー の行番号を返す。
front_matter_line() {
  awk -v key="$2" '
    NR == 1 && $0 == "---" { inside = 1; next }
    inside && $0 == "---" { exit }
    inside && index($0, key ":") == 1 { print NR; exit }
  ' "$1"
}

# DOC-08: status・updated・related。変更した資料は updated が今日であること。
check_front_matter() {
  local file="$1" kind="$2" status updated related item line
  if [ "$(head -n 1 "$file")" != "---" ]; then
    finding "$file" 1 "フロントマターがない（DOC-08）"
    return
  fi
  status=$(front_matter_value "$file" status)
  line=$(front_matter_line "$file" status)
  if [ "$kind" = "task" ]; then
    case "$status" in todo|in-progress|done|paused) ;; *) finding "$file" "${line:-1}" "status が todo / in-progress / done / paused のどれでもない: '$status'（DOC-08）" ;; esac
  else
    case "$status" in draft|final|retired) ;; *) finding "$file" "${line:-1}" "status が draft / final / retired のどれでもない: '$status'（DOC-08）" ;; esac
  fi
  updated=$(front_matter_value "$file" updated)
  line=$(front_matter_line "$file" updated)
  if ! printf '%s' "$updated" | grep -Eqx '[0-9]{4}-[0-9]{2}-[0-9]{2}'; then
    finding "$file" "${line:-1}" "updated が YYYY-MM-DD の日付でない: '$updated'（DOC-08）"
  elif [ "$updated" != "$TODAY" ] && [ -n "$(git -C "$ROOT" status --porcelain -- "$file" 2>/dev/null)" ]; then
    finding "$file" "$line" "変更したのに updated が今日（$TODAY）でない（DOC-08）"
  fi
  related=$(front_matter_value "$file" related)
  line=$(front_matter_line "$file" related)
  case "$related" in
    \[*\])
      for item in $(related_of "$file"); do
        printf '%s' "$item" | grep -Eqx '(REQ|DES|TASK)-[0-9]{3}|ADR-[0-9]{4}' \
          || finding "$file" "$line" "related に ID でない値がある: '$item'（DOC-08）"
      done ;;
    *) finding "$file" "${line:-1}" "related が [ID, ...] の形でない（DOC-08）" ;;
  esac
}

# DOC-18: （未記入）。TASK は、状態に応じて埋まっているべき欄だけを見る。
check_blanks() {
  local file="$1" kind="$2" status
  if [ "$kind" != "task" ]; then
    grep -n '（未記入）' "$file" | grep -v '^[0-9]*:>' | while IFS=: read -r line _; do
      finding "$file" "$line" "（未記入）が残っている（DOC-18）"
    done
    return
  fi
  status=$(front_matter_value "$file" status)
  awk -v status="$status" '
    /^## / {
      section = $0
      required = (section == "## 現在のフェーズ" || section == "## 次の一手" || (status == "done" && section == "## 完了したこと"))
      next
    }
    required && /（未記入）/ { print NR "\t" section }
  ' "$file" | while IFS=$'\t' read -r line section; do
    finding "$file" "$line" "「${section#\#\# }」が（未記入）のまま（DOC-14・DOC-18）"
  done
}

# 表の各行の列数が、表の1行目と同じであること（エスケープした \| とコードブロックの中は数えない）。
check_tables() {
  awk '
    /^```/ { fenced = !fenced; next }
    fenced { next }
    /^[ \t]*\|/ {
      row = $0; gsub(/\\\|/, "", row)
      cells = gsub(/\|/, "|", row) - 1
      if (!in_table) { in_table = 1; header = cells; next }
      if (cells != header) print NR "\t" header "\t" cells
      next
    }
    { in_table = 0 }
  ' "$1" | while IFS=$'\t' read -r line header cells; do
    finding "$1" "$line" "表の列数が1行目と違う（1行目 $header 列、この行 $cells 列）。セルの中の | は \\| にする"
  done
}

# DOC-07: テンプレートの見出し（## と ###。<…> や 000 を含む見出しは除く）がそろっていること。
check_sections() {
  local file="$1" template="$2" heading
  [ -n "$template" ] && [ -f "$template" ] || return 0
  grep -E '^###? ' "$template" | grep -v '<' | grep -v '000' | while IFS= read -r heading; do
    grep -qxF -- "$heading" "$file" || finding "$file" 1 "テンプレートの見出し「$heading」がない（DOC-07）"
  done
}

# test-items.md（$3）の DES（$1）の項目番号 $2 の、最後の行の行番号を返す。
test_item_line() {
  awk -v id="$1" -v n="$2" '
    /^## / { inside = (index($0, "## " id " ") == 1 || $0 == "## " id); next }
    inside && $0 ~ "^\\| *" n " *\\|" { line = NR }
    END { print line }
  ' "$3"
}

# TEST-11: test-items.md の項目番号は DES の中で重複せず、HEAD で欠番だった番号を使わない。
check_test_items() {
  local file="$1" base des_id number numbers base_numbers max
  base=$(mktemp)
  git -C "$ROOT" show "HEAD:$(to_relative "$file")" > "$base" 2>/dev/null || : > "$base"
  grep -oE '^## DES-[0-9]{3}' "$file" | sed 's/^## //' | sort -u | while IFS= read -r des_id; do
    numbers=$(test_item_numbers_of "$des_id" "$file")
    for number in $(printf '%s\n' "$numbers" | sort -n | uniq -d); do
      finding "$file" "$(test_item_line "$des_id" "$number" "$file")" "$des_id の項目番号 #$number が重複している（TEST-11）"
    done
    base_numbers=$(test_item_numbers_of "$des_id" "$base")
    max=$(printf '%s\n' "$base_numbers" | sort -n | tail -n 1)
    [ -n "$max" ] || continue
    for number in $(printf '%s\n' "$numbers" | sort -nu); do
      [ "$number" -le "$max" ] || continue
      printf '%s\n' "$base_numbers" | grep -qx "$number" \
        || finding "$file" "$(test_item_line "$des_id" "$number" "$file")" "$des_id の項目番号 #$number は欠番の再利用になっている。#$((max + 1)) 以降を使う（TEST-11）"
    done
  done
  rm -f "$base"
}

# DOC-01: 存在しない資料 ID の参照。
check_references() {
  missing_documents_in "$1" | while IFS= read -r reference; do
    finding "$1" "$(printf '%s' "$reference" | cut -d: -f2)" "${reference##*:} の資料が存在しない（DOC-01）"
  done
}

lint() {
  local file="$1" kind template
  read -r kind template <<< "$(kind_of "$file")"
  check_front_matter "$file" "$kind"
  check_blanks "$file" "$kind"
  check_tables "$file"
  check_sections "$file" "$template"
  [ "$(to_relative "$file")" = "docs/project/test-items.md" ] && check_test_items "$file"
  check_references "$file"
}

if [ $# -eq 0 ]; then
  [ -d "$PROJECT_DIR" ] || { echo "docs/project/ がない"; exit 0; }
  # ファイル名に空白はない（DOC-04）。
  # shellcheck disable=SC2046
  set -- $(find "$PROJECT_DIR" -name '*.md' -type f | sort)
fi
output=$(
  for file in "$@"; do
    case "$file" in /*) ;; *) file="$ROOT/$file" ;; esac
    [ -f "$file" ] || { finding "$file" 0 "ファイルがない"; continue; }
    lint "$file"
  done
)
if [ -n "$output" ]; then
  printf '%s\n' "$output"
  exit 1
fi
echo "指摘なし"
