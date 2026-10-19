---
name: release
description: develop の内容を main に入れてリリースするときに使う。全要件の実装が終わったとき、またはリリースを頼まれたときに、版番号を決め、develop から main への PR、マージ、タグ、リリースノートまでを行う。
argument-hint: "[版番号（省略時は GIT-51 で決める）]"
---
# リリース

対象: `$ARGUMENTS`（版番号。空なら GIT-51 で決める）。基準は GIT-50〜52。

## 準備
1. 未読なら（圧縮で内容が消えた場合も）`docs/guidelines/git.md` を読む。
2. `git switch develop && git pull --ff-only` で develop を最新にする。次のどれかに当たれば止めて、理由をユーザーに伝える。(1) `in-progress`・`paused` の TASK がある（他のブランチも含め、`bash .claude/scripts/progress.sh` で確かめる） (2) develop にマージしていない作業ブランチがある（`git branch -a --no-merged develop`） (3) tech.md のテスト、リント、ビルドのどれかが失敗する

## 版番号と内容
3. 版番号を決める。`$ARGUMENTS` がなければ `git describe --tags --abbrev=0 --match 'v[0-9]*' main` で前回のタグを得て、`git log <前回のタグ>..develop --format=%s` のコミットから GIT-51 で決める（タグがなければ `v1.0.0`）。
4. 前回のタグ以降にマージした作業ブランチを `git log <前回のタグ>..develop --merges --first-parent --format=%s` で一覧にする（タグがなければ全件）。

## PR と承認
5. `gh pr create --base main --head develop --title "release: <版番号>" --body <本文>` で PR を作る。本文には版番号、決めた理由、4 の一覧を書く。
6. `gh pr checks <PR 番号> --watch` で CI の結果を待つ。承認パケット（GIT-30。差分リンクは `bash .claude/scripts/branch.sh link main` と PR のリンク）で承認を求める。返答の後に PR へのコメントも読む（GIT-32）。

## マージとタグ
7. 承認されたら、CI の成功を確かめてから `gh pr merge <PR 番号> --merge` でマージする（develop は削除しない）。
8. `git switch main && git pull --ff-only` の後、`git tag -a <版番号> -m "<版番号>"` でタグを付けて `git push origin <版番号>` でプッシュし、`gh release create <版番号> --generate-notes` でリリースノートを作る。
9. `git switch develop` に戻り、版番号とリリースノートのリンクを報告する。

`origin` がない場合は、5〜8 の代わりに承認後 `git switch main && git merge --no-ff develop` でマージしてタグを付け、`git switch develop` に戻る（GIT-33）。
