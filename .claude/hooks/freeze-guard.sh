#!/usr/bin/env bash
# PreToolUse（Edit|Write|Bash）: 進行中 TASK の frozen_tests にあるファイルへの書き込みを止める（TEST-04）。
# Bash はコマンド文字列で判定するため、典型的な書き込みの形だけを止める。残りは REV-25 で検出する。
set -u
. "$(dirname "$0")/lib.sh"

# 書き込みを伴う Bash の形（リダイレクトは別に判定する）。その場編集、移動・複製・削除、git での復元、スクリプトからの書き込み。
WRITE_PATTERN="$INPLACE_EDIT_PATTERN"'|(^|[^[:alnum:]_-])(tee|mv|cp|rm|truncate|install|ln|patch|dd)([[:space:]]|$)|git[[:space:]]+(checkout|restore|reset|stash|apply|rm|mv)|open[[:space:]]*\(|write[A-Za-z_]*[[:space:]]*\('

# 区切った単位 $1 が、ファイル名 $2 を含むパスへリダイレクトしているか。
redirects_to() {
  redirect_targets "$1" | grep -qF -- "$2"
}

block() {
  printf '%s は %s で凍結されている（TEST-04）。テストを変えずに実装を直す。テストが誤っていると判断したら、作業を止めてユーザーに報告する（TEST-05）。凍結したファイルを読むだけなら、書き込みのコマンドと分けて実行する。\n' \
    "$1" "$(to_relative "$2")" >&2
  exit 2
}

input=$(cat)
tool=$(tool_name_of "$input")

if [ "$tool" = "Bash" ]; then
  # &&・;・| などで区切った単位ごとに、書き込みの形と凍結ファイルの名前が同じ単位にあるときだけ止める。
  segments=$(command_segments "$(bash_command_of "$input")")
  while IFS= read -r task; do
    while IFS= read -r frozen; do
      [ -n "$frozen" ] || continue
      frozen=$(to_relative "$frozen")
      # cd した後の相対参照も拾うため、パスではなくファイル名で判定する。
      name=${frozen##*/}
      while IFS= read -r segment; do
        case "$segment" in *"$name"*) ;; *) continue ;; esac
        if printf '%s' "$segment" | grep -Eq -- "$WRITE_PATTERN" || redirects_to "$segment" "$name"; then
          block "$frozen" "$task"
        fi
      done <<< "$segments"
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
