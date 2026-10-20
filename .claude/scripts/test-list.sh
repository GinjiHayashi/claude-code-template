#!/usr/bin/env bash
# テストの整理（TEST-24）の前後比較のため、テストの一覧とテストの説明の `DES-xxx #n` の一覧を保存・比較する。
# テストの一覧は tech.md の「テスト（一覧）」のコマンドの出力を使う（「なし」なら `DES-xxx #n` の一覧だけを比べる）。
# 保存先は .claude/review/（コミットしない）。
# 使い方:
#   test-list.sh save <名前>           .claude/review/test-list-<名前>.txt に保存する
#   test-list.sh compare <前> <後>     2つの一覧を比べ、違いがあれば表示して 1 を返す
set -u
. "$(dirname "$0")/../hooks/lib.sh"
cd "$ROOT" || exit 1

OUT_DIR="$ROOT/.claude/review"

fail() { printf 'test-list.sh: %s\n' "$1" >&2; exit 1; }

file_of() { printf '%s/test-list-%s.txt' "$OUT_DIR" "$1"; }

# テストの一覧（並べ替え済み）と、`DES-xxx #n` ごとの出現数を出力する。
inventory() {
  local command list excludes="" dir
  command=$(tech_command "テスト（一覧）")
  echo "## テストの一覧（tech.md「テスト（一覧）」）"
  if [ -n "$command" ]; then
    list=$(bash -c "$command") || fail "「テスト（一覧）」のコマンドが失敗した: $command"
    printf '%s\n' "$list" | sed 's/[[:space:]]*$//' | sed '/^$/d' | LC_ALL=C sort
  else
    echo "（なし）"
  fi
  echo "## DES-xxx #n ごとの出現数"
  for dir in $EXCLUDED_DIRS; do excludes="$excludes --exclude-dir=$dir"; done
  # shellcheck disable=SC2086
  grep -rhoE $excludes --exclude='*.md' 'DES-[0-9]+ ?#[0-9]+' "$ROOT" 2>/dev/null \
    | sed 's/ #/#/' | LC_ALL=C sort | uniq -c
}

[ $# -ge 1 ] || fail "サブコマンド（save / compare）を指定する"
case "$1" in
  save)
    [ $# -eq 2 ] || fail "save <名前>"
    mkdir -p "$OUT_DIR"
    inventory > "$(file_of "$2")" || exit 1
    printf '保存した: %s\n' "$(to_relative "$(file_of "$2")")"
    ;;
  compare)
    [ $# -eq 3 ] || fail "compare <前> <後>"
    [ -f "$(file_of "$2")" ] || fail "$(to_relative "$(file_of "$2")") がない。先に save する"
    [ -f "$(file_of "$3")" ] || fail "$(to_relative "$(file_of "$3")") がない。先に save する"
    if diff -u "$(file_of "$2")" "$(file_of "$3")"; then
      echo "一致した（テストの一覧と DES-xxx #n の一覧）"
    else
      echo "test-list.sh: 一覧が一致しない。テストの名前か DES-xxx #n が変わっている（TEST-24）" >&2
      exit 1
    fi
    ;;
  *) fail "不明なサブコマンド: $1" ;;
esac
