#!/usr/bin/env bash
# PreToolUse（Bash）: main / develop への直接のコミット・マージ・プッシュを止める（GIT-02）。
# コマンド文字列で判定するため、典型的な形だけを止める。リモートの保護は GitHub のルールセットで行う（README 2.1）。
set -u
. "$(dirname "$0")/lib.sh"

PROTECTED_PATTERN='^(main|develop)$'

block() {
  printf '%s（GIT-02）。作業ブランチ（GIT-03）で作業し、PR で入れる。\n' "$1" >&2
  exit 2
}

input=$(cat)
[ "$(tool_name_of "$input")" = "Bash" ] || exit 0
command=$(bash_command_of "$input")
case "$command" in *git*) ;; *) exit 0 ;; esac

cwd=$(cwd_of "$input")
branch=$(git -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null || true)
has_origin=0
git -C "$cwd" remote get-url origin >/dev/null 2>&1 && has_origin=1

# ; && || | で区切った1つずつのコマンドを調べる。
while IFS= read -r segment; do
  # git の後のオプション（-C <パス>、-c <設定>）を飛ばしてサブコマンドを得る。
  read -r -a words <<< "$segment"
  i=0
  while [ $i -lt ${#words[@]} ] && [ "${words[$i]}" != "git" ]; do i=$((i + 1)); done
  [ $i -lt ${#words[@]} ] || continue
  i=$((i + 1))
  while [ $i -lt ${#words[@]} ]; do
    case "${words[$i]}" in
      -C|-c) i=$((i + 2)) ;;
      -*) i=$((i + 1)) ;;
      *) break ;;
    esac
  done
  [ $i -lt ${#words[@]} ] || continue
  sub="${words[$i]}"
  args=("${words[@]:$((i + 1))}")

  case "$sub" in
    commit)
      [[ "$branch" =~ $PROTECTED_PATTERN ]] && block "$branch に直接コミットしようとした"
      ;;
    merge)
      if [[ "$branch" =~ $PROTECTED_PATTERN ]]; then
        # --ff-only は手元を最新にするだけなので通す。origin がない場合は GIT-33 の例外として通す。
        case " ${args[*]-} " in *" --ff-only "*) continue ;; esac
        [ "$has_origin" = 0 ] && continue
        block "$branch に直接マージしようとした"
      fi
      ;;
    push)
      refspecs=()
      remote_seen=0
      for word in "${args[@]-}"; do
        case "$word" in
          --all|--mirror) block "すべてのブランチをプッシュしようとした" ;;
          -*|"") ;;
          *)
            if [ "$remote_seen" = 0 ]; then remote_seen=1; else refspecs+=("$word"); fi
            ;;
        esac
      done
      # 送り先を指定しない場合は、現在のブランチが送り先になる。
      [ ${#refspecs[@]} -gt 0 ] || refspecs=("$branch")
      for refspec in "${refspecs[@]}"; do
        destination="${refspec#+}"
        destination="${destination##*:}"
        [ "$destination" = "HEAD" ] && destination="$branch"
        destination="${destination#refs/heads/}"
        [[ "$destination" =~ $PROTECTED_PATTERN ]] && block "$destination に直接プッシュしようとした"
      done
      ;;
  esac
done < <(printf '%s\n' "$command" | sed -E 's/(&&|\|\||;|\|)/\n/g')
exit 0
