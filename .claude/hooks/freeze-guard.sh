#!/usr/bin/env bash
# PreToolUse（Edit|Write|Bash）: 進行中 TASK の frozen_tests にあるファイルへの書き込みを止める（TEST-04）。
# Bash はコマンド文字列で判定するため、典型的な書き込みの形だけを止める。残りは REV-25 で検出する。
set -u
. "$(dirname "$0")/lib.sh"

# 書き込みを伴う Bash の形（リダイレクトは別に判定する）。その場編集、移動・複製・削除、git での復元、スクリプトからの書き込み。
WRITE_PATTERN='(^|[^[:alnum:]_-])(sed|perl|ruby)[[:space:]]+(-[[:alnum:]]*[[:space:]]+)*-[[:alnum:]]*i|(^|[^[:alnum:]_-])(tee|mv|cp|rm|truncate|install|ln|patch|dd)([[:space:]]|$)|git[[:space:]]+(checkout|restore|reset|stash|apply|rm|mv)|open[[:space:]]*\(|write[A-Za-z_]*[[:space:]]*\('

# 正規表現の特殊文字をエスケープする。
escape_regex() {
  printf '%s' "$1" | sed 's/[][\\.*^$+?(){}|/]/\\&/g'
}

# コマンドが、ファイル名 $2 を含むパスへリダイレクト（> / >>）しているか。2>&1 などは対象外。
redirects_to() {
  printf '%s' "$1" | grep -Eq -- ">[[:space:]]*[\"']?[^[:space:]|;&<>]*$(escape_regex "$2")"
}

block() {
  printf '%s は %s で凍結されている（TEST-04）。テストを変えずに実装を直す。テストが誤っていると判断したら、作業を止めてユーザーに報告する（TEST-05）。\n' \
    "$1" "$(to_relative "$2")" >&2
  exit 2
}

input=$(cat)
tool=$(tool_name_of "$input")

if [ "$tool" = "Bash" ]; then
  command=$(bash_command_of "$input")
  has_write_form=0
  printf '%s' "$command" | grep -Eq -- "$WRITE_PATTERN" && has_write_form=1
  while IFS= read -r task; do
    while IFS= read -r frozen; do
      [ -n "$frozen" ] || continue
      frozen=$(to_relative "$frozen")
      # cd した後の相対参照も拾うため、パスではなくファイル名で判定する。
      name=${frozen##*/}
      case "$command" in *"$name"*) ;; *) continue ;; esac
      if [ "$has_write_form" = 1 ] || redirects_to "$command" "$name"; then
        block "$frozen" "$task"
      fi
    done < <(frozen_tests_of "$task")
  done < <(in_progress_tasks)
  exit 0
fi

file=$(read_file_path "$input")
[ -n "$file" ] || exit 0
target=$(to_relative "$file")

while IFS= read -r task; do
  while IFS= read -r frozen; do
    [ -n "$frozen" ] || continue
    [ "$target" = "$(to_relative "$frozen")" ] && block "$target" "$task"
  done < <(frozen_tests_of "$task")
done < <(in_progress_tasks)
exit 0
