#!/usr/bin/env bash
# PreToolUse（Bash）: リポジトリ内のファイルを Bash で書き換えるコマンドを止める（CLAUDE.md「重大な落とし穴」）。
# 対象はリダイレクト（> / >> / &>）、tee、その場編集（sed -i、perl -pi、ruby -i）。コマンド文字列で判定するため、典型的な形だけを止める。
# 止めないもの: リポジトリの外、/dev/、行き先が変数で決まるもの、ALLOWED_DIRS の下（レビュー用の差分など）。
# ツールが生成するロックファイルや task.sh による TASK の更新は、コマンド文字列に書き込みの形が出ないため対象にならない。
set -u
. "$(dirname "$0")/lib.sh"

# 書き込んでよいリポジトリ内のフォルダ（リポジトリ直下からの相対パス）。
ALLOWED_DIRS=".claude/review/"

input=$(cat)
[ "$(tool_name_of "$input")" = "Bash" ] || exit 0
cwd=$(cwd_of "$input")
root=$(realpath -m -- "$ROOT")

# 書き込み先 $1 が、止める対象（リポジトリ内で ALLOWED_DIRS の外）なら、リポジトリ直下からの相対パスを出力して 0 を返す。
guarded_path() {
  local target="$1" path relative allowed
  target="${target#[\"\']}"; target="${target%[\"\']}"
  case "$target" in ""|'$'*|*'$('*|*'`'*|'~'*|/dev/*|-*) return 1 ;; esac
  case "$target" in /*) path="$target" ;; *) path="$cwd/$target" ;; esac
  path=$(realpath -m -- "$path")
  case "$path" in "$root"/*) relative="${path#"$root"/}" ;; *) return 1 ;; esac
  for allowed in $ALLOWED_DIRS; do
    case "$relative" in "$allowed"*) return 1 ;; esac
  done
  printf '%s' "$relative"
}

block() {
  printf '%s を Bash で書き換えようとした（CLAUDE.md）。ファイルの作成・編集は Edit / Write ツールで行う（凍結テストの保護とフォーマッターの hook を働かせるため）。読むだけなら、書き込みのコマンドと分けて実行する。\n' "$1" >&2
  exit 2
}

while IFS= read -r segment; do
  [ -n "$segment" ] || continue
  # リダイレクト
  while IFS= read -r target; do
    relative=$(guarded_path "$target") && block "$relative"
  done < <(redirect_targets "$segment")
  read -r -a words <<< "$segment"
  # tee の書き込み先（単位の先頭が tee のときの、オプション以外の引数）
  if [ "${words[0]-}" = "tee" ]; then
    for word in "${words[@]:1}"; do
      relative=$(guarded_path "$word") && block "$relative"
    done
  fi
  # その場編集: 引数のうち、リポジトリ内に実在するファイル
  if printf '%s' "$segment" | grep -Eq -- "$INPLACE_EDIT_PATTERN"; then
    for word in "${words[@]}"; do
      relative=$(guarded_path "$word") || continue
      [ -f "$root/$relative" ] && block "$relative"
    done
  fi
done < <(command_segments "$(bash_command_of "$input")")
exit 0
