#!/usr/bin/env bash
# テンプレートの更新を取り込む（README「テンプレートの更新を取り込む」）。create-repo.sh で作ったリポジトリの直下で実行する。
# 使い方:
#   update-template.sh
#   環境変数 TEMPLATE_REPO で取り込み元を変えられる（remote template がないときだけ使う。既定は GinjiHayashi/claude-code-template）
# 手順:
#   1. remote template がなければ足し、template の main と origin の develop を取ってくる
#   2. develop から feature/template-update を切り、template/main をマージコミットで取り込む。衝突したら止めて続け方を表示する
#   3. branch.sh pr でプッシュし、develop への下書き PR を作る（マージは GIT-22・23 のとおり）
set -eu

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
DEFAULT_TEMPLATE="GinjiHayashi/claude-code-template"
BRANCH="feature/template-update"
TITLE="chore: テンプレートの更新を取り込む"
cd "$ROOT"

fail() { printf 'update-template.sh: %s\n' "$1" >&2; exit 1; }

is_name() { [[ "$1" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; }
to_url() { if is_name "$1"; then printf 'https://github.com/%s.git' "$1"; else printf '%s' "$1"; fi; }
# 比べるために URL の末尾の .git と大文字小文字の違いをなくす。
normalize() { printf '%s' "${1%.git}" | tr '[:upper:]' '[:lower:]'; }

has_origin() { git remote get-url origin >/dev/null 2>&1; }
develop_ref() { if has_origin; then printf 'origin/develop'; else printf 'develop'; fi; }

[ -z "$(git status --porcelain --untracked-files=no)" ] || fail "コミットしていない変更がある。コミットしてから実行する（GIT-10）"

# 1. remote template
if ! git remote get-url template >/dev/null 2>&1; then
  url=$(to_url "${TEMPLATE_REPO:-$DEFAULT_TEMPLATE}")
  echo "remote template（$url）を足す"
  git remote add template "$url"
fi
if has_origin && [ "$(normalize "$(git remote get-url origin)")" = "$(normalize "$(git remote get-url template)")" ]; then
  fail "ここはテンプレートそのもの（origin と template が同じ）。作ったリポジトリで実行する"
fi
git fetch --quiet template main
if has_origin; then git fetch --quiet origin develop; fi
base=$(develop_ref)

# 2. develop から作業ブランチを切り、template/main を取り込む
git merge-base "$base" template/main >/dev/null 2>&1 \
  || fail "テンプレートと共通の履歴がない（create-repo.sh を使わずに作ったリポジトリ）。差分は手で取り込む"
if git merge-base --is-ancestor template/main "$base"; then
  echo "取り込む更新はない（develop はテンプレートの main を含んでいる）"
  exit 0
fi
if git show-ref --verify --quiet "refs/heads/$BRANCH" || { has_origin && [ -n "$(git ls-remote --heads origin "$BRANCH")" ]; }; then
  fail "$BRANCH がすでにある。前回の取り込みの PR をマージしてから実行するか、そのブランチで続ける"
fi
git switch --quiet --no-track -c "$BRANCH" "$base"
if ! git merge --quiet --no-ff -m "$TITLE" template/main; then
  printf '%s\n' \
    "update-template.sh: 衝突したので止めた（$BRANCH でマージの途中）。衝突したファイル:" \
    "$(git diff --name-only --diff-filter=U)" \
    "テンプレートの変更とこのリポジトリの変更の両方を残すように直す。直したら:" \
    "  git add <ファイル> && git commit --no-edit && bash .claude/scripts/branch.sh pr" \
    "やめるときは: git merge --abort && git switch develop && git branch -D $BRANCH" >&2
  exit 1
fi

# 3. プッシュと下書き PR
bash "$ROOT/.claude/scripts/branch.sh" pr
echo "変わったファイルを確かめ、CI の成功を確かめてからマージコミットでマージする（GIT-22・23）"
