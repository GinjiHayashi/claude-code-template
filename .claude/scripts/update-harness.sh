#!/usr/bin/env bash
# ハーネス（このテンプレート）の更新を取り込む（docs/harness.md「2.11 ハーネスの更新を取り込む」）。
# create-repo.sh で作ったリポジトリの直下で `npm run update-harness` で実行する。
# 手順:
#   1. remote harness がなければ足し（.env の HARNESS_REPO。空なら GinjiHayashi/claude-code-template）、
#      harness の main と origin の develop を取ってくる
#   2. develop から feature/harness-update を切り、harness/main をマージコミットで取り込む。衝突したら止めて続け方を表示する
#   3. branch.sh pr でプッシュし、develop への下書き PR を作る（マージは GIT-22・23 のとおり）
set -eu

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
DEFAULT_HARNESS="GinjiHayashi/claude-code-template"
BRANCH="feature/harness-update"
TITLE="chore: ハーネスの更新を取り込む"
cd "$ROOT"

fail() { printf 'update-harness.sh: %s\n' "$1" >&2; exit 1; }

is_name() { [[ "$1" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; }
to_url() { if is_name "$1"; then printf 'https://github.com/%s.git' "$1"; else printf '%s' "$1"; fi; }
# 比べるために URL の末尾の .git と大文字小文字の違いをなくす。
normalize() { printf '%s' "${1%.git}" | tr '[:upper:]' '[:lower:]'; }
# .env の HARNESS_REPO を読む（環境変数で指定がないとき）。
env_harness() {
  local value=""
  [ -f .env ] && value=$(sed -n 's/^HARNESS_REPO=//p' .env | tail -n 1)
  value="${value%\"}"; printf '%s' "${HARNESS_REPO:-${value#\"}}"
}

has_origin() { git remote get-url origin >/dev/null 2>&1; }
develop_ref() { if has_origin; then printf 'origin/develop'; else printf 'develop'; fi; }

[ -z "$(git status --porcelain --untracked-files=no)" ] || fail "コミットしていない変更がある。コミットしてから実行する（GIT-10）"

# 1. remote harness
if ! git remote get-url harness >/dev/null 2>&1; then
  harness=$(env_harness)
  url=$(to_url "${harness:-$DEFAULT_HARNESS}")
  echo "remote harness（$url）を足す"
  git remote add harness "$url"
fi
if has_origin && [ "$(normalize "$(git remote get-url origin)")" = "$(normalize "$(git remote get-url harness)")" ]; then
  fail "ここはハーネスそのもの（origin と harness が同じ）。作ったリポジトリで実行する"
fi
git fetch --quiet harness main
if has_origin; then git fetch --quiet origin develop; fi
base=$(develop_ref)

# 2. develop から作業ブランチを切り、harness/main を取り込む
git merge-base "$base" harness/main >/dev/null 2>&1 \
  || fail "ハーネスと共通の履歴がない（create-repo.sh を使わずに作ったリポジトリ）。差分は手で取り込む"
if git merge-base --is-ancestor harness/main "$base"; then
  echo "取り込む更新はない（develop はハーネスの main を含んでいる）"
  exit 0
fi
if git show-ref --verify --quiet "refs/heads/$BRANCH" || { has_origin && [ -n "$(git ls-remote --heads origin "$BRANCH")" ]; }; then
  fail "$BRANCH がすでにある。前回の取り込みの PR をマージしてから実行するか、そのブランチで続ける"
fi
git switch --quiet --no-track -c "$BRANCH" "$base"
# 直下の README.md はこのリポジトリの側を残す（.gitattributes の merge=ours が使うドライバ）。
git config merge.ours.driver true
if ! git merge --quiet --no-ff -m "$TITLE" harness/main; then
  printf '%s\n' \
    "update-harness.sh: 衝突したので止めた（$BRANCH でマージの途中）。衝突したファイル:" \
    "$(git diff --name-only --diff-filter=U)" \
    "ハーネスの変更とこのリポジトリの変更の両方を残すように直す。直したら:" \
    "  git add <ファイル> && git commit --no-edit && bash .claude/scripts/branch.sh pr" \
    "やめるときは: git merge --abort && git switch develop && git branch -D $BRANCH" >&2
  exit 1
fi

# 3. プッシュと下書き PR
bash "$ROOT/.claude/scripts/branch.sh" pr
echo "変わったファイルを確かめ、CI の成功を確かめてからマージコミットでマージする（GIT-22・23）"
