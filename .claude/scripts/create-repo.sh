#!/usr/bin/env bash
# ハーネス（このテンプレート）から開発用のリポジトリを作る（README「1. 開発用のリポジトリを作る」）。
# ハーネスの直下で人間が `npm run create-repo` で実行する。`-- --dry-run` なら、することを表示するだけ。
# 設定は .env（.env.sample を写して書く）か環境変数。引数の指定は .env より優先する:
#   npm run create-repo -- [<owner/name | URL>] [--dir <clone 先>] [--public] [--dry-run]
#     REPO          （引数 owner/name | URL）作るリポジトリ。owner/name なら gh で作成と設定まで行う。
#                   URL は先に作った空のリポジトリ（gh を使わないとき。設定は最後に表示する手順で行う）
#     REPO_DIR      （引数 --dir）手元に clone する場所。空ならハーネスの隣（../<name>）
#     HARNESS_REPO  複製元。空なら GinjiHayashi/claude-code-template
#     --public      公開リポジトリにする。既定は非公開
# 手順:
#   1. リポジトリを作る（既にあれば、空であることと公開・非公開が指定どおりであることを確かめる）
#   2. ハーネスの main と develop を履歴ごと送る（作業ブランチは送らない）
#   3. 既定ブランチ develop、マージコミットだけ、マージ後のブランチの自動削除を設定する
#   4. ルールセット protect-main-develop を作る（GIT-01・02・24。使えないプランでは警告だけ出す）
#   5. 手元に clone し、更新の取り込み（npm run update-harness）用の remote harness を足す
set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_HARNESS="GinjiHayashi/claude-code-template"
RULESET_NAME="protect-main-develop"

fail() { printf 'create-repo.sh: %s\n' "$1" >&2; exit 1; }
warn() { printf 'create-repo.sh: 警告: %s\n' "$1" >&2; }

# .env の KEY=VALUE を読む。決めた項目だけを、環境変数で指定がないときに使う。
load_env() {
  local line key value
  [ -f "$1" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|'#'*) continue ;; esac
    key="${line%%=*}"; value="${line#*=}"
    value="${value%\"}"; value="${value#\"}"
    case "$key" in REPO|REPO_DIR|HARNESS_REPO) [ -n "${!key-}" ] || printf -v "$key" '%s' "$value" ;; esac
  done < "$1"
}

# owner/name は GitHub の URL に直す。URL や手元のパスはそのまま使う。
is_name() { [[ "$1" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; }
to_url() { if is_name "$1"; then printf 'https://github.com/%s.git' "$1"; else printf '%s' "$1"; fi; }

load_env "$ROOT/.env"
repo="${REPO-}" dir="${REPO_DIR-}" visibility="private" dry_run=false
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) [ $# -ge 2 ] || fail "--dir に場所を指定する"; dir="$2"; shift 2 ;;
    --public) visibility="public"; shift ;;
    --dry-run) dry_run=true; shift ;;
    -*) fail "不明な指定: $1" ;;
    *) repo="$1"; shift ;;
  esac
done
[ -n "$repo" ] && [ "$repo" != "your-name/my-app" ] \
  || fail "REPO が未設定（.env.sample を .env に写し、owner/リポジトリ名 を書く）"

harness_url=$(to_url "${HARNESS_REPO:-$DEFAULT_HARNESS}")
repo_url=$(to_url "$repo")
name=$(basename "$repo" .git)
dir="${dir:-$ROOT/../$name}"
dir="${dir/#\~/$HOME}"

# dry-run のときは表示だけ、それ以外は表示してから実行する。
step() {
  local msg="$1"; shift
  if $dry_run; then printf '[dry-run] %s\n' "$msg"; else printf '%s\n' "$msg"; "$@"; fi
}

[ ! -e "$dir" ] || fail "clone 先がすでにある: $dir（REPO_DIR で別の場所を指定する）"

use_gh=false
if is_name "$repo" && gh auth status >/dev/null 2>&1; then use_gh=true; fi

# 1. リポジトリを用意する。中身があるリポジトリには送らない（上書きを防ぐ）。
exists=false
if $use_gh; then
  if gh repo view "$repo" >/dev/null 2>&1; then
    exists=true
    actual=$(gh repo view "$repo" --json visibility --jq .visibility)
    [ "$actual" = "$(printf '%s' "$visibility" | tr '[:lower:]' '[:upper:]')" ] \
      || fail "$repo は $actual である。指定（$visibility）と違うので止める（公開するなら --public）"
  else
    step "$visibility のリポジトリ $repo を作る" gh repo create "$repo" "--$visibility"
  fi
fi
if ! $use_gh || $exists || ! $dry_run; then
  refs=$(git ls-remote "$repo_url" 2>/dev/null) \
    || fail "$repo_url に届かない。空のリポジトリを先に作るか、gh にログインする（gh auth login）"
  [ -z "$refs" ] || fail "$repo_url が空ではない。上書きしないよう止める（README やライセンスを付けずに作り直す）"
fi

# 2. ハーネスの main と develop を履歴ごと送る。
push_harness() (
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  git clone --quiet --bare "$harness_url" "$tmp"
  git -C "$tmp" push --quiet "$repo_url" main develop
)
step "$harness_url の main と develop を $repo_url へ送る" push_harness

# 3・4. GitHub の設定。
create_ruleset() {
  gh api --method POST "repos/$repo/rulesets" --input - >/dev/null <<EOF || warn "ルールセットを作れなかった（非公開の Free プランでは使えない）。CI の確認は Claude が行う（GIT-25）"
{
  "name": "$RULESET_NAME",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["refs/heads/main", "refs/heads/develop"], "exclude": [] } },
  "rules": [
    { "type": "pull_request", "parameters": {
        "required_approving_review_count": 0, "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false, "require_last_push_approval": false,
        "required_review_thread_resolution": false } },
    { "type": "non_fast_forward" },
    { "type": "deletion" },
    { "type": "required_status_checks", "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": [ { "context": "ci" } ] } }
  ]
}
EOF
}
if $use_gh; then
  step "既定ブランチを develop にし、マージコミットだけにし、マージ後のブランチの自動削除を有効にする" \
    gh repo edit "$repo" --default-branch develop --enable-merge-commit \
      --enable-squash-merge=false --enable-rebase-merge=false --delete-branch-on-merge
  step "ルールセット $RULESET_NAME を作る（main と develop に PR 必須、強制プッシュ禁止、削除禁止、必須チェック ci）" create_ruleset
fi

# 5. 手元に clone し、remote harness を足す。
step "$dir に develop を clone する" git clone --quiet --branch develop "$repo_url" "$dir"
step "remote harness（$harness_url）を足す" git -C "$dir" remote add harness "$harness_url"

if ! $use_gh; then
  cat <<'EOF'
残りの手順（GitHub の Settings で行う）:
  - General → Default branch を develop にする
  - General → Pull Requests で「Allow merge commits」だけを有効にし、「Automatically delete head branches」を有効にする
  - Rules → Rulesets で main と develop に「PR を必須」「強制プッシュの禁止」「削除の禁止」「必須チェック ci」を設定する（使えるプランのとき）
EOF
fi
printf '次は: cd %s && claude\n' "$dir"
