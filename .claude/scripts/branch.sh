#!/usr/bin/env bash
# 作業ブランチの作成、PR の作成・下書きの解除・マージ、承認用の差分リンクの出力を行う。規則は docs/guidelines/git.md（GIT-04・21〜25・31・33・61）。
# 使い方:
#   branch.sh start <ブランチ名>           develop の最新から作業ブランチを切る（マージされていない同名のブランチがあれば切り替え、
#                                          マージ済みなら止める。GIT-06）。起点のコミットを出力する
#   branch.sh start hotfix                 main の最新のタグから hotfix/v<次のパッチ版> を切る
#   branch.sh pr                           プッシュし、現在のブランチの開いている PR がなければ下書き PR を作って、URL を出力する
#                                          （同名のブランチのマージ済み PR は対象にしない。ready・merge も開いている PR を対象にする）
#   branch.sh ready                        プッシュして PR の下書きを解除し、HEAD の CI の結果を待つ（origin がなければ ci.sh を実行する）
#   branch.sh merge                        HEAD の CI の成功を確かめて PR をマージし、develop を最新にする（hotfix/ は main へ入れ、ブランチを残す。
#                                          CI の取り消しは1回だけ再実行し、GitHub の一時的な失敗（5xx）のマージは3回まで試す。
#                                          --local-ci なら CI の代わりに手元で ci.sh を実行する。CI 基盤の障害のときだけ使う（GIT-26）。
#                                          origin がなければ develop へ --no-ff でマージする）
#   branch.sh link <起点のコミット>        起点から HEAD までの比較の URL を出力する（origin がなければ git diff --stat）
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

# 同名のブランチ（ローカル、origin）が target にマージ済みなら止める（GIT-06）。マージされていなければ再利用できる。
refuse_merged() {
  local name="$1" target="$2" ref
  git rev-parse --verify --quiet "$target" >/dev/null || return 0
  for ref in "refs/heads/$name" "refs/remotes/origin/$name"; do
    git show-ref --verify --quiet "$ref" || continue
    # 切った直後でコミットがまだないブランチ（target と同じコミット）は再利用してよい。
    [ "$(git rev-parse "$ref")" != "$(git rev-parse "$target")" ] || continue
    git merge-base --is-ancestor "$ref" "$target" || continue
    fail "$name は ${target#origin/} にマージ済み（${ref#refs/}）のため再利用しない（GIT-06）。別の名前にするか、古いブランチを消す（git branch -D $name）"
  done
}

cmd_start() {
  [ $# -eq 1 ] || fail "start <ブランチ名 | hotfix>"
  local name="$1" base tag version major minor patch
  [ -z "$(git status --porcelain --untracked-files=no)" ] || fail "コミットしていない変更がある。コミットしてから切り替える（GIT-10）"
  if has_origin; then git fetch --quiet --tags --prune origin; fi
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
  case "$name" in hotfix/*) refuse_merged "$name" "$(upstream_of main)" ;; *) refuse_merged "$name" "$base" ;; esac
  if git show-ref --verify --quiet "refs/heads/$name"; then
    git switch --quiet "$name"
    if has_origin && git rev-parse --verify --quiet "origin/$name" >/dev/null; then
      git merge --quiet --ff-only "origin/$name"
    fi
  elif has_origin && git rev-parse --verify --quiet "origin/$name" >/dev/null; then
    git switch --quiet -c "$name" --track "origin/$name"
  else
    git rev-parse --verify --quiet "$base" >/dev/null || fail "$base がない。docs/harness.md 2.1 の準備で develop を作る"
    git switch --quiet --no-track -c "$name" "$base"
  fi
  printf 'ブランチ: %s\n起点のコミット: %s\n' "$name" "$(git rev-parse --short=12 HEAD)"
}

# ブランチの開いている PR の番号を返す。なければ空。同名のブランチのマージ済み・閉じた PR は対象にしない。
open_pr() {
  gh pr list --head "$1" --state open --json number --jq '.[0].number // empty'
}

# 現在のブランチの開いている PR の番号を返す。なければ止める。
require_open_pr() {
  local number
  number=$(open_pr "$1")
  [ -n "$number" ] || fail "$1 の開いている PR がない。branch.sh pr で作る"
  printf '%s' "$number"
}

cmd_pr() {
  [ $# -eq 0 ] || fail "pr は引数を取らない"
  local branch base number
  branch=$(current_branch)
  case "$branch" in main|develop) fail "$branch では PR を作らない（GIT-02）" ;; esac
  if ! has_origin; then
    echo "origin がないため PR は作らない（GIT-33）"
    return 0
  fi
  git push --quiet -u origin "$branch"
  number=$(open_pr "$branch")
  if [ -n "$number" ]; then
    gh pr view "$number" --json url --jq .url
    return 0
  fi
  case "$branch" in hotfix/*) base=main ;; *) base=develop ;; esac
  if [ -f "$PR_TEMPLATE" ]; then
    gh pr create --draft --base "$base" --head "$branch" --title "$branch" --body-file "$PR_TEMPLATE"
  else
    gh pr create --draft --base "$base" --head "$branch" --title "$branch" --body ""
  fi
}

# コミットの CI（ci.yml）の実行が終わるまで待ち、成功なら 0、失敗・未登録なら 1 を返す（GIT-25）。
# プッシュ直後は実行がまだ登録されていないため、最大2分待つ。下書きのときの実行（ジョブを飛ばした実行）は数えない。
# 取り消された実行は1回だけ再実行する。
watch_checks() {
  local sha="$1" ignored=" " rerun="" run_id id run_conclusion job_conclusion _
  for _ in $(seq 1 24); do
    run_id=""
    for id in $(gh run list --commit "$sha" --workflow ci.yml --json databaseId --jq '.[].databaseId'); do
      case "$ignored" in *" $id "*) ;; *) run_id="$id"; break ;; esac
    done
    if [ -z "$run_id" ]; then sleep 5; continue; fi
    gh run watch "$run_id" --exit-status >/dev/null 2>&1 || true
    read -r run_conclusion job_conclusion < <(gh run view "$run_id" --json conclusion,jobs \
      --jq '"\(.conclusion) \([.jobs[].conclusion][0] // "none")"')
    case "$run_conclusion $job_conclusion" in
      "success success") return 0 ;;
      *" skipped") ignored="$ignored$run_id " ;;
      "cancelled "*)
        [ -z "$rerun" ] || return 1
        rerun=1
        echo "branch.sh: CI の実行が取り消されたため、1回だけ再実行する" >&2
        gh run rerun "$run_id"
        sleep 5 ;;
      *) return 1 ;;
    esac
  done
  return 1
}

# PR をマージする。GitHub の一時的な失敗（5xx）なら、間隔を空けて3回まで試す。
merge_pr() {
  local number="$1" attempt out
  shift
  for attempt in 1 2 3; do
    if out=$(gh pr merge "$number" --merge "$@" 2>&1); then
      [ -z "$out" ] || printf '%s\n' "$out"
      return 0
    fi
    printf '%s\n' "$out" >&2
    # 失敗と表示されても、GitHub 側ではマージが済んでいることがある。
    [ "$(gh pr view "$number" --json state --jq .state 2>/dev/null)" != MERGED ] || return 0
    case "$out" in *"HTTP 5"[0-9][0-9]*|*"Bad Gateway"*|*"Service Unavailable"*|*"Gateway Timeout"*) ;; *) return 1 ;; esac
    [ "$attempt" -lt 3 ] || break
    echo "branch.sh: GitHub の一時的な失敗のため、$((attempt * 10)) 秒後に再試行する" >&2
    sleep $((attempt * 10))
  done
  return 1
}

cmd_ready() {
  [ $# -eq 0 ] || fail "ready は引数を取らない"
  local branch number
  branch=$(current_branch)
  if ! has_origin; then
    bash "$ROOT/.claude/scripts/ci.sh"
    return
  fi
  cmd_pr
  number=$(require_open_pr "$branch")
  if [ "$(gh pr view "$number" --json isDraft --jq .isDraft)" = true ]; then
    gh pr ready "$number"
  fi
  watch_checks "$(git rev-parse HEAD)" \
    || fail "CI が失敗したか、実行が登録されていない。失敗なら同じブランチで直す。登録されない（Actions が無効）なら ci.sh を手元で実行する（GIT-25）"
}

cmd_merge() {
  local local_ci="" branch base number
  case "$*" in "") ;; --local-ci) local_ci=1 ;; *) fail "merge [--local-ci]" ;; esac
  branch=$(current_branch)
  case "$branch" in main|develop) fail "$branch はマージ元にしない（GIT-02）" ;; hotfix/*) base=main ;; *) base=develop ;; esac
  [ -z "$(git status --porcelain --untracked-files=no)" ] || fail "コミットしていない変更がある。コミットしてからマージする（GIT-10）"
  if ! has_origin; then
    git switch --quiet "$base"
    git merge --no-ff "$branch"
    return
  fi
  git push --quiet -u origin "$branch"
  number=$(require_open_pr "$branch")
  if [ -n "$local_ci" ]; then
    # CI 基盤の障害で CI が動かないときだけ使う。ユーザーの承認と TASK への記録は呼ぶ側で行う（GIT-26）。
    bash "$ROOT/.claude/scripts/ci.sh" || fail "手元の ci.sh が失敗したためマージしない（GIT-26）"
    echo "branch.sh: 手元の ci.sh の成功で CI に代えてマージする（GIT-26）。マージ後に $base の CI の結果を確かめる" >&2
  else
    watch_checks "$(git rev-parse HEAD)" || fail "CI が成功していないためマージしない（GIT-25）"
  fi
  case "$branch" in
    hotfix/*) merge_pr "$number" ;;
    *) merge_pr "$number" --delete-branch ;;
  esac || fail "PR #$number をマージできなかった。表示されたエラーを確かめる"
  git switch --quiet "$base"
  git pull --quiet --ff-only
  printf 'マージした: %s → %s\n' "$branch" "$base"
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
  # ローカルにないブランチ名（main など）は origin/<name> で解決する。
  sha=$(git rev-parse --verify --quiet "$1^{commit}" || git rev-parse --verify --quiet "$(upstream_of "$1")^{commit}") \
    || fail "コミット $1 がない"
  if ! has_origin; then
    git diff --stat "$sha" HEAD
    return 0
  fi
  if [ -z "$(git branch -r --contains HEAD 2>/dev/null)" ]; then
    echo "branch.sh: HEAD がまだプッシュされていない。先にプッシュする（GIT-20）" >&2
  fi
  printf '%s/compare/%s..%s\n' "$(web_url)" "$(git rev-parse --short=12 "$sha")" "$(git rev-parse --short=12 HEAD)"
}

[ $# -ge 1 ] || fail "サブコマンド（start / pr / ready / merge / link）を指定する"
sub="$1"; shift
case "$sub" in
  start) cmd_start "$@" ;;
  pr) cmd_pr "$@" ;;
  ready) cmd_ready "$@" ;;
  merge) cmd_merge "$@" ;;
  link) cmd_link "$@" ;;
  *) fail "不明なサブコマンド: $sub" ;;
esac
