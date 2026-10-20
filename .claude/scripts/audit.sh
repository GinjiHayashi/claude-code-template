#!/usr/bin/env bash
# プロジェクト全体の点検のうち、機械で判定できる観点（RF-20・24・25・26）を調べ、指摘を REV-17 の表の行で出力する。
# ファイルは変更しない。基準の正本は docs/guidelines/refactoring.md。
# 使い方:
#   audit.sh
set -u
. "$(dirname "$0")/../hooks/lib.sh"

DOCS_DIR="$ROOT/docs"
PROJECT_DIR="$DOCS_DIR/project"
TEST_ITEMS="$PROJECT_DIR/test-items.md"

# 指摘を1行出力する（番号は最後に振る）。引数: 観点 根拠ルール 場所 問題 修正案
finding() {
  printf '| 0 | P1 | %s | %s | %s | %s | %s |\n' "$1" "$2" "$3" "$4" "$5"
}

# ID（例: DES-003）の資料ファイルを返す。なければ空。
document_of() {
  local folder
  case "$1" in
    REQ-*) folder=requirements ;; DES-*) folder=design ;; ADR-*) folder=adr ;; TASK-*) folder=tasks ;; *) return 0 ;;
  esac
  ls "$PROJECT_DIR/$folder/$1"-*.md 2>/dev/null | head -n 1
}

# test-items.md の見出し「## DES-xxx」の下にある表の項目番号を1行1件で返す。
test_item_numbers_of() {
  [ -f "$TEST_ITEMS" ] || return 0
  awk -v id="$1" '
    /^## / { inside = (index($0, "## " id " ") == 1 || $0 == "## " id); next }
    inside && /^\| *[0-9]+ *\|/ { n = $0; sub(/^\| */, "", n); sub(/ *\|.*$/, "", n); print n }
  ' "$TEST_ITEMS"
}

# RF-20: テストの DES-xxx #n と、final の DES の test-items.md の見出し。
check_traceability() {
  local excludes="" dir des file reference location des_id number status
  for dir in $EXCLUDED_DIRS; do excludes="$excludes --exclude-dir=$dir"; done
  # shellcheck disable=SC2086
  grep -rnoE $excludes --exclude='*.md' 'DES-[0-9]+ #[0-9]+' "$ROOT" 2>/dev/null | while IFS= read -r reference; do
    location=$(to_relative "${reference%:DES-*}")
    des_id=$(printf '%s' "${reference##*:}" | cut -d' ' -f1)
    number=$(printf '%s' "${reference##*#}")
    file=$(document_of "$des_id")
    if [ -z "$file" ]; then
      finding RF-20 TEST-12 "$location" "$des_id の DES がない" "参照を正しい DES に直す"
      continue
    fi
    status=$(front_matter_value "$file" status)
    if [ "$status" = "retired" ]; then
      finding RF-20 TEST-09 "$location" "retired の $des_id を参照するテストが残っている" "変更要求の候補にする（RF-40 (2)）"
    elif ! test_item_numbers_of "$des_id" | grep -qx "$number"; then
      finding RF-20 TEST-12 "$location" "$des_id #$number が test-items.md にない" "test-items.md かテストの説明を直す"
    fi
  done
  for des in "$PROJECT_DIR"/design/DES-*.md; do
    [ -f "$des" ] || continue
    [ "$(front_matter_value "$des" status)" = "final" ] || continue
    des_id=$(basename "$des" | sed 's/^\(DES-[0-9]*\)-.*/\1/')
    grep -q "^## $des_id\( \|$\)" "$TEST_ITEMS" 2>/dev/null \
      || finding RF-20 TEST-11 "$(to_relative "$des")" "test-items.md に $des_id の見出しがない" "test-items.md に見出しと項目を足す"
  done
}

# RF-24: docs/README.md の表のパスと、docs/project/ 直下の資料。
check_index() {
  local index="$DOCS_DIR/README.md" path file name
  [ -f "$index" ] || return 0
  grep -oE '^\| `(guidelines|project)/[^`]*`' "$index" | sed 's/^| `//; s/`$//' | while IFS= read -r path; do
    # コア資料は開発の流れの中で作られるので、まだなくてよい。
    case "$path" in
      guidelines/*) ;;
      project/overview.md|project/tech.md|project/architecture.md|project/glossary.md|project/test-items.md|project/*/) continue ;;
    esac
    [ -e "$DOCS_DIR/$path" ] || finding RF-24 DOC-09 "docs/README.md" "\`$path\` が存在しない" "表の行を消すか、資料を作る"
  done
  for file in "$PROJECT_DIR"/*.md; do
    [ -f "$file" ] || continue
    name=$(basename "$file")
    grep -q "\`project/$name\`" "$index" || finding RF-24 DOC-09 "docs/README.md" "project/$name が表にない" "表に行を足す"
  done
}

# RF-25: 定義されていないルール ID と、存在しない資料 ID の参照。
check_references() {
  local defined id target
  # 定義は箇条書き（`- **WF-01** …`）と、列が3つ以上の表の行（`| WF-05 | …`）にある。
  defined=$(grep -hoE '^(- \*\*|\| )(WF|PLAN|TEST|REV|DOC|CODE|RF|GIT)-[0-9]+(\*\*| \|)' "$DOCS_DIR"/guidelines/*.md | grep -oE '[A-Z]+-[0-9]+' | sort -u)
  for target in "$ROOT/CLAUDE.md" "$ROOT/README.md" "$DOCS_DIR" "$ROOT/.claude/skills" "$ROOT/.claude/agents" "$ROOT/.claude/hooks" "$ROOT/.claude/scripts"; do
    [ -e "$target" ] || continue
    grep -rnoE '(^|[^A-Za-z])(WF|PLAN|TEST|REV|DOC|CODE|RF|GIT)-[0-9]+' "$target" 2>/dev/null | while IFS= read -r reference; do
      id=$(printf '%s' "$reference" | grep -oE '(WF|PLAN|TEST|REV|DOC|CODE|RF|GIT)-[0-9]+$')
      printf '%s\n' "$defined" | grep -qx "$id" \
        || finding RF-25 DOC-01 "$(to_relative "${reference%%:*}"):$(printf '%s' "$reference" | cut -d: -f2)" "ルール $id が guidelines に定義されていない" "正しいルール ID に直す"
    done
  done
  grep -rnoE '(REQ|DES|TASK)-[0-9]{3}|ADR-[0-9]{4}' "$PROJECT_DIR" 2>/dev/null | while IFS= read -r reference; do
    id=${reference##*:}
    case "$id" in *-000|*-0000) continue ;; esac
    [ -n "$(document_of "$id")" ] \
      || finding RF-25 DOC-01 "$(to_relative "${reference%%:*}"):$(printf '%s' "$reference" | cut -d: -f2)" "$id の資料が存在しない" "参照を直す"
  done
}

# RF-26: status の整合。
check_status() {
  local file des req_id req_file all_retired
  for file in "$PROJECT_DIR"/*.md "$PROJECT_DIR"/*/*.md; do
    [ -f "$file" ] || continue
    [ "$(front_matter_value "$file" status)" = "final" ] || continue
    grep -q '（未記入）' "$file" && finding RF-26 DOC-18 "$(to_relative "$file")" "final なのに（未記入）が残っている" "記入するか status を draft に戻す"
  done
  for des in "$PROJECT_DIR"/design/DES-*.md; do
    [ -f "$des" ] || continue
    [ "$(front_matter_value "$des" status)" = "retired" ] && continue
    all_retired=""
    for req_id in $(related_of "$des"); do
      req_file=$(document_of "$req_id")
      # 存在しない ID は RF-25 で指摘する。
      [ -n "$req_file" ] || continue
      case "$req_id" in REQ-*) ;; *) continue ;; esac
      if [ "$(front_matter_value "$req_file" status)" = "retired" ]; then
        all_retired=${all_retired:-yes}
      else
        all_retired=no
      fi
    done
    [ "$all_retired" = "yes" ] && finding RF-26 PLAN-24 "$(to_relative "$des")" "retired の REQ だけを担う DES が retired でない" "削除の設計にする（変更要求の候補。RF-40 (2)）"
  done
}

echo "| # | 重要度 | 観点 | ルールID | 場所 | 問題 | 修正案 |"
echo "|---|---|---|---|---|---|---|"
output=$( { check_traceability; check_index; check_references; check_status; } )
if [ -n "$output" ]; then
  printf '%s\n' "$output" | awk -F'|' 'BEGIN { OFS = "|" } { $2 = " " NR " "; print }'
else
  echo "指摘なし"
fi
