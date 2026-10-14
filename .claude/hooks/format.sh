#!/usr/bin/env bash
# PostToolUse（Edit|Write）: 編集したファイルを tech.md のフォーマットコマンドで整形する。
# コマンドが未記入・「なし」なら何もしない。整形の失敗は Claude に伝える（exit 2）。
set -u
. "$(dirname "$0")/lib.sh"

file=$(read_file_path)
[ -n "$file" ] && [ -f "$file" ] || exit 0
command=$(tech_command "フォーマット（1ファイル指定）")
[ -n "$command" ] || exit 0

extensions=$(tech_command "フォーマット対象の拡張子")
if [ -n "$extensions" ]; then
  case " $extensions " in
    *" .${file##*.} "*) ;;
    *) exit 0 ;;
  esac
fi

cd "$ROOT" || exit 0
if ! output=$(eval "$command \"\$file\"" 2>&1); then
  printf 'フォーマットに失敗した: %s %s\n%s\n' "$command" "$(to_relative "$file")" "$output" >&2
  exit 2
fi
exit 0
