#!/usr/bin/env bash
# tech.md の開発コマンドを順に実行して、テスト・リント・フォーマット・ビルドを確かめる。規則は docs/guidelines/git.md（GIT-24・25）。
# CI（.github/workflows/ci.yml）から呼ぶ。GitHub を使わない場合（GIT-33）は手元で実行する。
# 使い方:
#   ci.sh    tech.md が final でなければ全体を飛ばす。final なら「なし」の操作だけ飛ばし、未記入の操作は失敗にする
set -u
. "$(dirname "$0")/../hooks/lib.sh"
cd "$ROOT" || exit 1

failed=""

# GitHub Actions ではログの注記として出す。手元ではそのまま表示する。
annotate() {
  local level="$1" message="$2"
  if [ "${GITHUB_ACTIONS-}" = true ]; then
    printf '::%s::%s\n' "$level" "$message"
  else
    printf '[%s] %s\n' "$level" "$message"
  fi
}

group_start() { if [ "${GITHUB_ACTIONS-}" = true ]; then printf '::group::%s\n' "$1"; else printf '== %s\n' "$1"; fi; }
group_end() { if [ "${GITHUB_ACTIONS-}" = true ]; then echo '::endgroup::'; fi; }

# 作業ツリーの未コミットの差分を1つの値にまとめる（整形の前後で比べるため）。
tree_state() { git diff --binary | git hash-object --stdin; }

# 操作を1つ実行する。戻り値: 0 成功・飛ばした、1 失敗。
run_step() {
  local operation="$1" value before after
  value=$(tech_value "$operation")
  case "$value" in
    "なし")
      annotate notice "$operation: tech.md で「なし」のため飛ばした"
      return 0 ;;
    ""|"（未記入）"*)
      annotate error "$operation: tech.md のコマンドが未記入である。コマンドか「なし」を書く"
      failed="$failed $operation"
      return 1 ;;
  esac
  group_start "$operation: $value"
  [ "$operation" = "フォーマット" ] && before=$(tree_state)
  if ! eval "$value"; then
    group_end
    annotate error "$operation が失敗した: $value"
    failed="$failed $operation"
    return 1
  fi
  if [ "$operation" = "フォーマット" ]; then
    after=$(tree_state)
    if [ "$before" != "$after" ]; then
      group_end
      annotate error "フォーマット: 整形で差分が出た。整形した結果をコミットする（対象: $(git diff --name-only | tr '\n' ' ')）"
      failed="$failed $operation"
      return 1
    fi
  fi
  group_end
  return 0
}

if [ ! -f "$TECH_MD" ] || [ "$(front_matter_value "$TECH_MD" status)" != final ]; then
  annotate notice "docs/project/tech.md が final でないため、CI の確認をすべて飛ばした（開発開始の前）"
  exit 0
fi

if ! run_step "依存関係のインストール"; then
  annotate error "依存関係のインストールに失敗したため、以降の確認を中止した"
  exit 1
fi
for operation in "フォーマット" "リント" "ビルド" "テスト（全件）"; do
  run_step "$operation" || true
done

if [ -n "$failed" ]; then
  annotate error "失敗した操作:$failed"
  exit 1
fi
echo "すべての確認が成功した"
