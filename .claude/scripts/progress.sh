#!/usr/bin/env bash
# プロジェクトの進捗の材料（資料のフロントマターと TASK の記述）を集計して出力する。ファイルは変更しない。
# 実装状況の判定は WF-10、次の作業の決め方は WF-23、点検の提案は WF-25、報告の形は /progress Skill が正本。
# 使い方:
#   progress.sh
set -u
. "$(dirname "$0")/../hooks/lib.sh"

# 本文の最初の「# 」見出し（資料の題名）を返す。
title_of() {
  awk '/^# / { sub(/^# /, ""); print; exit }' "$1"
}

# 指定フォルダの資料（例: REQ-*.md）を番号順に1行1件で返す。
documents_in() {
  local file
  for file in "$1"/$2-*.md; do
    [ -f "$file" ] && printf '%s\n' "$file"
  done
}

# DES を related に持つ TASK のうち、番号が最も大きいものの status を返す。なければ「なし」。
implementation_status_of() {
  local des_id="$1" task latest="なし" id
  while IFS= read -r task; do
    for id in $(related_of "$task"); do
      [ "$id" = "$des_id" ] && latest=$(front_matter_value "$task" status)
    done
  done < <(documents_in "$PROJECT_DIR/tasks" TASK)
  printf '%s' "$latest"
}

print_kickoff() {
  local name file
  echo "## 開発開始の資料"
  for name in overview tech glossary architecture; do
    file="$PROJECT_DIR/$name.md"
    if [ -f "$file" ]; then
      echo "- $name.md: status=$(front_matter_value "$file" status)"
    else
      echo "- $name.md: なし"
    fi
  done
}

print_requirements() {
  local req req_id des des_id des_status line
  echo
  echo "## 要件と設計（retired を除く）"
  echo "| REQ | 題名 | status | DES（status / 実装の TASK の status） |"
  echo "|---|---|---|---|"
  while IFS= read -r req; do
    [ "$(front_matter_value "$req" status)" = "retired" ] && continue
    req_id=$(basename "$req" | sed 's/^\(REQ-[0-9]*\)-.*/\1/')
    line=""
    while IFS= read -r des; do
      des_status=$(front_matter_value "$des" status)
      [ "$des_status" = "retired" ] && continue
      case " $(related_of "$des") " in *" $req_id "*) ;; *) continue ;; esac
      des_id=$(basename "$des" | sed 's/^\(DES-[0-9]*\)-.*/\1/')
      line="${line:+$line、}$des_id（$des_status / $(implementation_status_of "$des_id")）"
    done < <(documents_in "$PROJECT_DIR/design" DES)
    echo "| $req_id | $(title_of "$req" | sed 's/^REQ-[0-9]* //') | $(front_matter_value "$req" status) | ${line:-（DES なし）} |"
  done < <(documents_in "$PROJECT_DIR/requirements" REQ)
}

print_tasks() {
  local task status title wanted count
  echo
  echo "## TASK"
  for wanted in in-progress paused todo; do
    echo "### status: $wanted"
    count=0
    while IFS= read -r task; do
      status=$(front_matter_value "$task" status)
      [ "$status" = "$wanted" ] || continue
      count=$((count + 1))
      echo "- $(to_relative "$task")（related: $(related_of "$task" | xargs)）"
      if [ "$wanted" != "todo" ]; then
        echo "  - 現在のフェーズ: $(section_of "$task" "## 現在のフェーズ" | paste -sd ' ' -)"
        echo "  - 次の一手: $(section_of "$task" "## 次の一手" | paste -sd ' ' -)"
      fi
    done < <(documents_in "$PROJECT_DIR/tasks" TASK)
    [ "$count" -gt 0 ] || echo "（なし）"
  done
  echo "### status: done"
  while IFS= read -r task; do
    [ "$(front_matter_value "$task" status)" = "done" ] || continue
    title=$(title_of "$task")
    echo "- $title"
  done < <(documents_in "$PROJECT_DIR/tasks" TASK)
}

# 実装順は要件定義と変更要求の TASK の「完了したこと」に書かれる（WF-03、WF-20）。
print_order_sources() {
  local task title
  echo
  echo "## 実装順の記録がある TASK"
  while IFS= read -r task; do
    title=$(title_of "$task")
    case "$title" in
      *" 要件定義"|*" 変更要求:"*) echo "- $(to_relative "$task")（$title）" ;;
    esac
  done < <(documents_in "$PROJECT_DIR/tasks" TASK)
}

print_open_issues() {
  local task issues
  echo
  echo "## 未解決事項（done 以外の TASK）"
  while IFS= read -r task; do
    [ "$(front_matter_value "$task" status)" = "done" ] && continue
    issues=$(section_of "$task" "## 未解決事項" | grep -v '^（なし）$')
    [ -n "$issues" ] || continue
    echo "- $(to_relative "$task")"
    printf '%s\n' "$issues" | sed 's/^/  /'
  done < <(documents_in "$PROJECT_DIR/tasks" TASK)
}

# TASK のファイルの番号を数で返す。
task_number_of() {
  printf '%s' $((10#$(basename "$1" | sed 's/^TASK-\([0-9]*\)-.*/\1/')))
}

# 最後に done になった点検（題名が「リファクタリング」）の TASK のファイルを返す。なければ空。
last_refactor_task() {
  local task last=""
  while IFS= read -r task; do
    [ "$(front_matter_value "$task" status)" = "done" ] || continue
    case "$(title_of "$task")" in *" リファクタリング") last="$task" ;; esac
  done < <(documents_in "$PROJECT_DIR/tasks" TASK)
  printf '%s' "$last"
}

# 最後の点検とその後に done になった TASK の「未解決事項」（レビューで残した P2 など。REV-11）。次の点検の材料にする。
print_left_issues() {
  local task last last_number=0 issues
  last=$(last_refactor_task)
  [ -n "$last" ] && last_number=$(task_number_of "$last")
  echo
  echo "## 残した P2 など（最後の点検とその後の done の TASK の未解決事項）"
  while IFS= read -r task; do
    [ "$(task_number_of "$task")" -ge "$last_number" ] || continue
    [ "$(front_matter_value "$task" status)" = "done" ] || continue
    issues=$(section_of "$task" "## 未解決事項" | grep -v '^（なし）$')
    [ -n "$issues" ] || continue
    echo "- $(to_relative "$task")"
    printf '%s\n' "$issues" | sed 's/^/  /'
  done < <(documents_in "$PROJECT_DIR/tasks" TASK)
}

# WF-25 の判定材料: 最後に done になった点検の TASK と、その後に done になった実装の TASK の件数。
print_refactor_basis() {
  local task last last_number=0 last_task="なし" implemented=0 has_des id
  last=$(last_refactor_task)
  if [ -n "$last" ]; then
    last_task=$(to_relative "$last")
    last_number=$(task_number_of "$last")
  fi
  while IFS= read -r task; do
    [ "$(task_number_of "$task")" -gt "$last_number" ] || continue
    [ "$(front_matter_value "$task" status)" = "done" ] || continue
    has_des=""
    for id in $(related_of "$task"); do
      case "$id" in DES-*) has_des=yes ;; esac
    done
    [ -n "$has_des" ] && implemented=$((implemented + 1))
  done < <(documents_in "$PROJECT_DIR/tasks" TASK)
  echo
  echo "## プロジェクト全体の点検の材料（WF-25）"
  echo "- 最後に done になった点検の TASK: $last_task"
  echo "- 点検の後の実装（done の実装の TASK）: $implemented 件"
}

echo "# 進捗の材料（$(date +%Y-%m-%d)）"
print_kickoff
print_requirements
print_tasks
print_order_sources
print_open_issues
print_left_issues
print_refactor_basis
