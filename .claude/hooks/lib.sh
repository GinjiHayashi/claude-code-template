#!/usr/bin/env bash
# hook 共通の関数。各 hook から source して使う。

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
TECH_MD="$ROOT/docs/project/tech.md"
TASKS_DIR="$ROOT/docs/project/tasks"
# テストの説明（DES-xxx #n）を探すときに除くフォルダ（資料、設定、生成物、依存ライブラリ）。Markdown のファイルも除く。
# shellcheck disable=SC2034  # audit.sh と test-list.sh が使う
EXCLUDED_DIRS=".git docs .claude node_modules vendor dist build target .venv"

# 標準入力の JSON から編集対象のパスを取り出す。jq がなければ sed で読む。
# 引数で JSON を渡した場合は、標準入力の代わりにそれを読む。
read_file_path() {
  local input
  input=${1-$(cat)}
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty'
    return
  fi
  printf '%s' "$input" | tr -d '\n' \
    | sed -n -e 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
             -e 's/.*"notebook_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
}

# JSON から tool_name を取り出す。
tool_name_of() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$1" | jq -r '.tool_name // empty'
    return
  fi
  printf '%s' "$1" | tr -d '\n' | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
}

# JSON から Bash のコマンドを取り出す。jq がなければ JSON 全体を返す（判定は部分一致なので足りる）。
bash_command_of() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$1" | jq -r '.tool_input.command // empty'
    return
  fi
  printf '%s' "$1"
}

# JSON からコマンドを実行するディレクトリ（cwd）を取り出す。取れなければ ROOT を返す。
cwd_of() {
  local cwd=""
  if command -v jq >/dev/null 2>&1; then
    cwd=$(printf '%s' "$1" | jq -r '.cwd // empty')
  else
    cwd=$(printf '%s' "$1" | tr -d '\n' | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  fi
  [ -d "$cwd" ] || cwd="$ROOT"
  printf '%s' "$cwd"
}

# 絶対パスをリポジトリ直下からの相対パスにする。
to_relative() {
  local path="$1"
  path="${path#"$ROOT"/}"
  printf '%s' "${path#./}"
}

PROJECT_DIR="$ROOT/docs/project"
TEST_ITEMS="$PROJECT_DIR/test-items.md"

# ID（例: DES-003）の資料ファイルを返す。なければ空。
document_of() {
  local folder
  case "$1" in
    REQ-*) folder=requirements ;; DES-*) folder=design ;; ADR-*) folder=adr ;; TASK-*) folder=tasks ;; *) return 0 ;;
  esac
  ls "$PROJECT_DIR/$folder/$1"-*.md 2>/dev/null | head -n 1
}

# 資料（ファイルかフォルダ）の中の資料 ID の参照のうち、資料が存在しないものを「パス:行:ID」で1行1件返す。
missing_documents_in() {
  local reference id
  grep -rHnoE '(REQ|DES|TASK)-[0-9]{3}|ADR-[0-9]{4}' "$@" 2>/dev/null | while IFS= read -r reference; do
    id=${reference##*:}
    case "$id" in *-000|*-0000) continue ;; esac
    [ -n "$(document_of "$id")" ] || printf '%s\n' "$reference"
  done
}

# test-items.md（$2 で別のファイルも指定できる）の見出し「## DES-xxx」の下にある表の項目番号を1行1件で返す。
test_item_numbers_of() {
  local file="${2:-$TEST_ITEMS}"
  [ -f "$file" ] || return 0
  awk -v id="$1" '
    /^## / { inside = (index($0, "## " id " ") == 1 || $0 == "## " id); next }
    inside && /^\| *[0-9]+ *\|/ { n = $0; sub(/^\| */, "", n); sub(/ *\|.*$/, "", n); print n }
  ' "$file"
}

# tech.md の「開発コマンド」表から、指定した操作の欄をそのまま返す（バッククォートは除く）。
tech_value() {
  local operation="$1"
  [ -f "$TECH_MD" ] || return 0
  awk -F'|' -v op="$operation" '
    { name = $2; gsub(/^[ \t]+|[ \t]+$/, "", name) }
    name == op { cmd = $3; gsub(/^[ \t]+|[ \t]+$/, "", cmd); gsub(/`/, "", cmd); print cmd; exit }
  ' "$TECH_MD"
}

# tech.md の「開発コマンド」表から、指定した操作のコマンドを返す。未記入・なしは空。
tech_command() {
  local value
  value=$(tech_value "$1")
  case "$value" in
    ""|"なし"|"（未記入）"*) return 0 ;;
  esac
  printf '%s' "$value"
}

# フロントマターの値を返す（1行の「キー: 値」だけを扱う）。
front_matter_value() {
  local file="$1" key="$2"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { inside = 1; next }
    inside && $0 == "---" { exit }
    inside && index($0, key ":") == 1 {
      value = substr($0, length(key) + 2)
      sub(/[ \t]+#.*$/, "", value); gsub(/^[ \t]+|[ \t]+$/, "", value)
      print value; exit
    }
  ' "$file"
}

# フロントマターの related（例: [REQ-001, REQ-002]）を空白区切りで返す。
related_of() {
  front_matter_value "$1" related | tr -d '[]' | tr ',' ' '
}

# status: in-progress / paused の TASK ファイルを1行1件で返す（paused 中も凍結を保つ）。
in_progress_tasks() {
  local task
  [ -d "$TASKS_DIR" ] || return 0
  for task in "$TASKS_DIR"/TASK-*.md; do
    [ -f "$task" ] || continue
    case "$(front_matter_value "$task" status)" in
      in-progress|paused) printf '%s\n' "$task" ;;
    esac
  done
}

# TASK のフロントマターの frozen_tests（ブロック形式の一覧）を1行1件で返す。
frozen_tests_of() {
  awk -v q="'" '
    NR == 1 && $0 == "---" { inside = 1; next }
    inside && $0 == "---" { exit }
    inside && /^frozen_tests:/ { listing = 1; next }
    listing && /^[ \t]*-[ \t]+/ {
      item = $0; sub(/^[ \t]*-[ \t]+/, "", item); sub(/[ \t]+#.*$/, "", item)
      gsub(/"/, "", item); gsub(q, "", item); print item; next
    }
    listing { listing = 0 }
  ' "$1"
}
