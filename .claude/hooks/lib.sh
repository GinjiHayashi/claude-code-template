#!/usr/bin/env bash
# hook 共通の関数。各 hook から source して使う。

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
TECH_MD="$ROOT/docs/project/tech.md"
TASKS_DIR="$ROOT/docs/project/tasks"

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

# 見出し $2（例: "## 次の一手"）のセクション本文（> の説明行と空行を除く）を返す。
section_of() {
  awk -v heading="$2" '
    /^## / { show = ($0 == heading); next }
    show && !/^>/ && NF { print }
  ' "$1"
}

# フロントマターの related（例: [REQ-001, REQ-002]）を空白区切りで返す。
related_of() {
  front_matter_value "$1" related | tr -d '[]' | tr ',' ' '
}

# その場編集の形（sed -i、perl -pi、ruby -i）。freeze-guard と bash-write-guard が使う。
# shellcheck disable=SC2034
INPLACE_EDIT_PATTERN='(^|[^[:alnum:]_-])(sed|perl|ruby)[[:space:]]+(-[[:alnum:]]*[[:space:]]+)*-[[:alnum:]]*i'

# Bash のコマンドからヒアドキュメントの本文を除く（本文の中の > や ; を書き込み・区切りと誤認しないため）。
strip_heredocs() {
  printf '%s\n' "$1" | awk '
    heredoc != "" { line = $0; sub(/^\t+/, "", line); if (line == heredoc) heredoc = ""; next }
    { print }
    match($0, /<<-?[ \t]*["\047]?[A-Za-z_][A-Za-z0-9_]*["\047]?/) && substr($0, RSTART - 1, 1) != "<" {
      word = substr($0, RSTART, RLENGTH); sub(/^<<-?[ \t]*/, "", word); gsub(/["\047]/, "", word); heredoc = word
    }
  '
}

# Bash のコマンドを、引用符の外の &&・||・;・| と改行で区切った単位に分け、1行1件で返す。ヒアドキュメントの本文は除く。
command_segments() {
  strip_heredocs "$1" | awk '
    {
      line = $0; out = ""; q = ""
      for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1); n = substr(line, i + 1, 1)
        if (q != "") { out = out c; if (c == q) q = ""; continue }
        if (c == "\047" || c == "\"") { q = c; out = out c; continue }
        if (c == ";" || c == "|" || (c == "&" && n == "&")) {
          print out; out = ""
          if (n == c) i++
          continue
        }
        out = out c
      }
      print out
    }
  '
}

# 区切った単位の中のリダイレクト（> / >> / >| / &>）の行き先を1行1件で返す。&1 などへの複製は含めない。
# 引用符の中の > は行き先にしない（行き先そのものの引用符は外す）。
redirect_targets() {
  printf '%s\n' "$1" \
    | sed -E "s/>([[:space:]]*)'([^']*)'/>\1\2/g; s/>([[:space:]]*)\"([^\"]*)\"/>\1\2/g; s/'[^']*'//g; s/\"[^\"]*\"//g" \
    | grep -oE '>>?\|?[[:space:]]*[^[:space:]&<>|;]+' \
    | sed -E 's/^>>?\|?[[:space:]]*//'
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
