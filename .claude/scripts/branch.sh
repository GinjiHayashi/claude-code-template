#!/usr/bin/env bash
# 作業ブランチの作成、下書き PR の作成、承認用の差分リンクの出力を行う。規則は docs/guidelines/git.md（GIT-04・21・31・33・61）。
# 使い方:
#   branch.sh start <ブランチ名>           develop の最新から作業ブランチを切る（既にあれば切り替える）。起点のコミットを出力する
#   branch.sh start hotfix                 main の最新のタグから hotfix/v<次のパッチ版> を切る
#   branch.sh pr                           現在のブランチの PR がなければプッシュして下書き PR を作り、URL を出力する
#   branch.sh link <起点のコミット>         起点から HEAD までの比較の URL を出力する（origin がなければ git diff --stat）
#   branch.sh link --commit <コミット>      1つのコミットのページの URL を出力する
set -eu

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PR_TEMPLATE="$ROOT/.github/pull_request_template.md"
cd "$ROOT"

fail() { printf 'branch.sh: %s\n' "$1" >&2; exit 1; }

has_origin() { git remote get-url origin >/dev/null 2>&1; }

current_branch() { git symbolic-ref --quiet --short HEAD || fail "ブランチ上にいない（detached HEAD）"; }

# origin があれば origin/<name>、なければ <name> を返す。
upstream_of() {
  if has_origin && git rev-parse --verify --quiet "origin/$1" >/dev/null; then
    printf 'origin/%s' "$1"
  else
    printf '%s' "$1"
  fi
}

# origin の URL を https://<host>/<owner>/<repo> の形にする。
web_url() {
  local url
  url=$(git remote get-url origin)
  url="${url%.git}"
  case "$url" in
    git@*:*) url="${url#git@}"; url="https://${url%%:*}/${url#*:}" ;;
    ssh://*) url="${url#ssh://}"; url="${url#*@}"; url="https://$url" ;;
    https://*@*) url="https://${url#*@}" ;;
  esac
  printf '%s' "$url"
}

cmd_start() {
  [ $# -eq 1 ] || fail "start <ブランチ名 | hotfix>"
  local name="$1" base tag version major minor patch
  [ -z "$(git status --porcelain --untracked-files=no)" ] || fail "コミットしていない変更がある。コミットしてから切り替える（GIT-10）"
  if has_origin; then git fetch --quiet --tags origin; fi
  if [ "$name" = hotfix ]; then
    tag=$(git describe --tags --abbrev=0 --match 'v[0-9]*' "$(upstream_of main)" 2>/dev/null) \
      || fail "main にリリースのタグがない。hotfix はリリースの後だけ使う（GIT-60）"
    version="${tag#v}"
    IFS=. read -r major minor patch <<< "$version"
    name="hotfix/v$major.$minor.$((patch + 1))"
    base="$tag"
  else
    case "$name" in feature/?*) ;; *) fail "作業ブランチは feature/ で始める（GIT-03）: $name" ;; esac
    base=$(upstream_of develop)
  fi
  if git show-ref --verify --quiet "refs/heads/$name"; then
    git switch --quiet "$name"
    if has_origin && git rev-parse --verify --quiet "origin/$name" >/dev/null; then
      git merge --quiet --ff-only "origin/$name"
    fi
  elif has_origin && git rev-parse --verify --quiet "origin/$name" >/dev/null; then
    git switch --quiet -c "$name" --track "origin/$name"
  else
    git rev-parse --verify --quiet "$base" >/dev/null || fail "$base がない。README 2.1 の準備で develop を作る"
    git switch --quiet --no-track -c "$name" "$base"
  fi
  printf 'ブランチ: %s\n起点のコミット: %s\n' "$name" "$(git rev-parse --short=12 HEAD)"
}

cmd_pr() {
  [ $# -eq 0 ] || fail "pr は引数を取らない"
  local branch base url
  branch=$(current_branch)
  case "$branch" in main|develop) fail "$branch では PR を作らない（GIT-02）" ;; esac
  if ! has_origin; then
    echo "origin がないため PR は作らない（GIT-33）"
    return 0
  fi
  git push --quiet -u origin "$branch"
  if url=$(gh pr view "$branch" --json url --jq .url 2>/dev/null); then
    printf '%s\n' "$url"
    return 0
  fi
  case "$branch" in hotfix/*) base=main ;; *) base=develop ;; esac
  if [ -f "$PR_TEMPLATE" ]; then
    gh pr create --draft --base "$base" --head "$branch" --title "$branch" --body-file "$PR_TEMPLATE"
  else
    gh pr create --draft --base "$base" --head "$branch" --title "$branch" --body ""
  fi
}

cmd_link() {
  local sha
  if [ "${1-}" = "--commit" ]; then
    [ $# -eq 2 ] || fail "link --commit <コミット>"
    sha=$(git rev-parse --verify "$2^{commit}") || fail "コミット $2 がない"
    if has_origin; then printf '%s/commit/%s\n' "$(web_url)" "$sha"; else git show --stat --format='%h %s' "$sha"; fi
    return 0
  fi
  [ $# -eq 1 ] || fail "link <起点のコミット>"
  sha=$(git rev-parse --verify "$1^{commit}") || fail "コミット $1 がない"
  if ! has_origin; then
    git diff --stat "$sha" HEAD
    return 0
  fi
  if [ -z "$(git branch -r --contains HEAD 2>/dev/null)" ]; then
    echo "branch.sh: HEAD がまだプッシュされていない。先にプッシュする（GIT-20）" >&2
  fi
  printf '%s/compare/%s..%s\n' "$(web_url)" "$(git rev-parse --short=12 "$sha")" "$(git rev-parse --short=12 HEAD)"
}

[ $# -ge 1 ] || fail "サブコマンド（start / pr / link）を指定する"
sub="$1"; shift
case "$sub" in
  start) cmd_start "$@" ;;
  pr) cmd_pr "$@" ;;
  link) cmd_link "$@" ;;
  *) fail "不明なサブコマンド: $sub" ;;
esac
