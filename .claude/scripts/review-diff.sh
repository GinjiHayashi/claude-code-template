#!/usr/bin/env bash
# レビュアーに渡す差分を .claude/review/<TASK-ID>-<種別>-r<ラウンド>.diff に保存し、パスを出力する（REV-13。手順は /review-loop）。
# 使い方:
#   review-diff.sh <TASK-ID> code <ラウンド> <起点のコミット>   起点（凍結コミットか起点のコミット）から作業ツリーまでの差分
#   review-diff.sh <TASK-ID> test <ラウンド> <テストファイル ...>  テストファイルの HEAD からの差分（新しいファイルも含める）
#   review-diff.sh <TASK-ID> plan <ラウンド> <資料 ...>           改訂した資料の HEAD からの差分。差分がなければ（新しく作った資料だけなら）保存しない
set -eu

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
REVIEW_DIR="$ROOT/.claude/review"
cd "$ROOT"

fail() { printf 'review-diff.sh: %s\n' "$1" >&2; exit 1; }

[ $# -ge 4 ] || fail "review-diff.sh <TASK-ID> <code|test|plan> <ラウンド> <起点のコミット | ファイル ...>"
task="$1" kind="$2" round="$3"
shift 3
case "$task" in TASK-[0-9]*) ;; *) fail "TASK の ID は TASK-xxx: $task" ;; esac
case "$round" in *[!0-9]*|"") fail "ラウンドは数字: $round" ;; esac

diff=$(
  case "$kind" in
    code)
      [ $# -eq 1 ] || fail "code は起点のコミットを1つだけ取る"
      git rev-parse --verify --quiet "$1^{commit}" >/dev/null || fail "コミット $1 がない"
      git diff "$1"
      ;;
    test)
      # まだ追跡していないテストファイルも差分に出す（内容はステージしない）。
      for file in "$@"; do
        [ -e "$file" ] || fail "$file がない"
        git ls-files --error-unmatch -- "$file" >/dev/null 2>&1 || git add -N -- "$file"
      done
      git diff HEAD -- "$@"
      ;;
    plan)
      git diff HEAD -- "$@"
      ;;
    *) fail "種別は code / test / plan のどれか: $kind" ;;
  esac
)

if [ -z "$diff" ]; then
  echo "差分なし（新しく作った資料だけなら差分は渡さない）"
  exit 0
fi
mkdir -p "$REVIEW_DIR"
out="$REVIEW_DIR/$task-$kind-r$round.diff"
printf '%s\n' "$diff" > "$out"
printf '%s\n' "${out#"$ROOT"/}"
