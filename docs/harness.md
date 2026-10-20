---
status: final
updated: 2026-10-20
related: []
---
# Claude Code 開発環境テンプレート（ハーネス）の説明

## 目次

- [1. 概要](#1-概要)
- [2. クイックスタート](#2-クイックスタート)
  - [2.1 共通の準備](#21-共通の準備)
    - [0. 必要なツールを入れる](#0-必要なツールを入れる)
    - [1. 開発用のリポジトリを作る](#1-開発用のリポジトリを作る)（[.env の書き方](#env-の書き方)）
    - [2. Claude Code を起動する](#2-claude-code-を起動する)
  - [2.2 新しいプロジェクトを始める](#22-新しいプロジェクトを始める)
  - [2.3 機能を追加する・仕様を変える・機能を削除する](#23-機能を追加する仕様を変える機能を削除する)
  - [2.4 小さな不具合や文言・設定を直す](#24-小さな不具合や文言設定を直す)
  - [2.5 ドキュメントだけを直す](#25-ドキュメントだけを直す)
  - [2.6 中断した作業を再開する](#26-中断した作業を再開する)
  - [2.7 進捗・次の作業・残作業を確かめる](#27-進捗次の作業残作業を確かめる)
  - [2.8 コード全体を整理し、資料どうしの齟齬を直す](#28-コード全体を整理し資料どうしの齟齬を直す)
  - [2.9 リリースする](#29-リリースする)
  - [2.10 リリース済みの本番の不具合を急いで直す（hotfix）](#210-リリース済みの本番の不具合を急いで直すhotfix)
  - [2.11 ハーネスの更新を取り込む](#211-ハーネスの更新を取り込む)
- [3. フォルダ・ファイル構成](#3-フォルダファイル構成)
- [4. 仕組み](#4-仕組み)
  - [4.1 人間の役割](#41-人間の役割)
  - [4.2 役割の分担](#42-役割の分担)
  - [4.3 hooks](#43-hooks)
  - [4.4 権限](#44-権限)
  - [4.5 外部サービス](#45-外部サービス)
  - [4.6 Git と CI](#46-git-と-ci)
- [5. Claude とのやり取り](#5-claude-とのやり取り)

## 1. 概要

Claude Code で開発を進めるための、言語に依存しない（Python や SQL などに依存しない）共通の開発環境です。

- 開発は **探索 → 計画 → 実装 → レビュー** を1サイクルとし、これを繰り返します。
- 実装はテスト駆動開発（TDD）で進めます。計画の完了後、実装より先にテストを書きます。
- レビューは文脈を引き継がないサブエージェントが行います。指摘は観点ごとに P0 / P1 / P2 に分類し、終了条件を定量的に決めます。
- 基準（ルール）の正本は `docs/guidelines/`、作業の手順の正本は各 Skill（`.claude/skills/`）です。同じことを2か所に書きません（SSoT）。この資料は人間向けの説明です（Claude は作業のために読みません）。

## 2. クイックスタート

やりたいことに合わせて、次の表から入口を選びます。ここでは人間がすることを中心に書きます。手順の正本は各 Skill（`.claude/skills/`）、開発の進め方の正本は [`docs/guidelines/workflow.md`](guidelines/workflow.md) です。

| やりたいこと | 入口 | 詳細 |
|---|---|---|
| 新しいプロジェクトを始める | `/kickoff` | 2.2 |
| 機能を追加する・仕様を変える・機能を削除する | `/plan-spec change <変更内容>` | 2.3 |
| 小さな不具合や文言・設定を直す | `/quick-change <変更内容>` | 2.4 |
| ドキュメントだけを直す | `/quick-change <変更内容>` | 2.5 |
| 中断した作業を再開する | `claude` を起動するだけ | 2.6 |
| 進捗・次の作業・残作業を確かめる | `/progress` | 2.7 |
| コード全体を整理し、資料どうしの齟齬を直す | `/refactor` | 2.8 |
| リリースする（develop を main に入れる） | `/release` | 2.9 |
| リリース済みの本番の不具合を急いで直す | `/quick-change hotfix <変更内容>` | 2.10 |
| ハーネス（このテンプレート）の更新を取り込む | `npm run update-harness` | 2.11 |

小さな変更かどうか迷ったら `/quick-change` から始めて構いません。条件（2.4）を満たさないと分かった時点で、Claude が変更要求に切り替えます（WF-19）。

### 2.1 共通の準備

このリポジトリ（ハーネス）はそのまま使わず、**複製して開発用のリポジトリを作り、そこで開発します**。

#### 0. 必要なツールを入れる

| ツール | 版 | 何に使うか | 確かめ方 |
|---|---|---|---|
| Node.js | 22 以上 | `npm run` でリポジトリの作成と更新の取り込みを呼ぶ | `node -v` |
| git | — | 版の管理。テストの凍結とレビューの差分にも使う | `git --version` |
| jq | — | hooks が Claude Code からの入力を読む | `jq --version` |
| Claude Code | — | 開発を進める AI | `claude --version` |
| GitHub CLI（推奨） | — | リポジトリと PR の作成 | `gh auth status` |

Ubuntu（Windows では WSL の Ubuntu）を前提にしています。bash は Ubuntu に入っています。

**Windows のとき**：PowerShell を管理者として開いて `wsl --install` を実行し、再起動して Ubuntu を開きます。以降のコマンドはすべて Ubuntu の中で打ちます。作業フォルダは Ubuntu 側（`~/` の下）に置きます（`/mnt/c/...` は遅いため）。

```sh
# git と curl と jq
sudo apt update && sudo apt install -y git curl jq

# Node.js（nvm で入れる。nvm を入れたら、新しいターミナルを開いてから次の行）
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
nvm install 22

# Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# GitHub CLI（公式の apt リポジトリを足して入れる）
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install -y gh
gh auth login   # GitHub にログイン（表示に従ってブラウザで認証する）
```

入れたら、新しいターミナルを開き、表の「確かめ方」のコマンドで版が出ることを確かめます。GitHub CLI がなくても進められますが、リポジトリの作成と設定を手で行うことになります。開発するものの言語の実行環境（Python など）は、技術・環境の資料で決めてから別に入れます。

#### 1. 開発用のリポジトリを作る

```sh
git clone https://github.com/GinjiHayashi/claude-code-template.git
cd claude-code-template
cp .env.sample .env        # .env を開いて書く（下の「.env の書き方」）
npm run create-repo
```

##### .env の書き方

書く項目は3つです。ふつうは `REPO` の1行だけを書きます。

| 項目 | 必須か | 書くもの |
|---|---|---|
| `REPO` | 必須 | 作る開発用リポジトリ（`持ち主/リポジトリ名`） |
| `REPO_DIR` | 任意 | 手元に clone する場所。空なら、このリポジトリの隣（`../<リポジトリ名>`） |
| `HARNESS_REPO` | 任意 | 複製元のハーネス。空なら `GinjiHayashi/claude-code-template` |

状況ごとの書き方：

| こんなとき | 書くこと |
|---|---|
| 自分のアカウントに作る（ふつうはこれ） | `REPO=your-name/my-app` |
| 組織（Organization）に作る | `REPO=your-org/my-app`（その組織でリポジトリを作る権限が要る） |
| GitHub に空のリポジトリをもう作ってある | 同じく `REPO=持ち主/名前`。空なら、そのまま使う（中身があれば止まる） |
| SSH で push したい | `REPO=git@github.com:your-name/my-app.git`。URL で書くと gh を使わないので、空のリポジトリを先に作り、最後に表示される設定を手で行う |
| clone する場所を決めたい | `REPO_DIR=~/work/my-app`（`~/` はホームのフォルダ） |
| ハーネスを自分のリポジトリに複製して直している | `HARNESS_REPO=your-name/claude-code-template` |

例（自分のアカウント `taro` に `todo-app` を作り、`~/work` の下に置く）：

```sh
REPO=taro/todo-app
REPO_DIR=~/work/todo-app
HARNESS_REPO=
```

既定では非公開のリポジトリを作ります。公開にするときは `npm run create-repo -- --public` を実行します。先に中身だけ確かめたいときは、`npm run create-repo -- --dry-run` を実行します（何も作らず、することを表示するだけ）。

これで GitHub にリポジトリができ、`REPO_DIR` の場所（既定はこのリポジトリの隣の `../my-app`）に clone されます。このあとの作業はすべてそちらで行います。最初に clone したこのリポジトリは消してかまいません。

作ったリポジトリの直下の `README.md` は、この説明への案内だけです。消さずに残しておくと、2.2 の `/kickoff` の最後で Claude がプロジェクトの説明に書き換えます。

<details>
<summary>スクリプトがしていること・gh がないとき</summary>

- リポジトリを作る（すでにあれば、空であることと公開・非公開が指定どおりであることを確かめる。中身があれば止める）
- ハーネスの `main` と `develop` を履歴ごと送る（作業ブランチは送らない。フォークは非公開にできないため複製する。GitHub Docs「Duplicating a repository」）
- 既定ブランチを `develop` にし、マージ方式をマージコミットだけにし、マージ後のブランチの自動削除を有効にする
- ルールセット `protect-main-develop` を作る（`main` と `develop` に PR 必須、強制プッシュ禁止、削除禁止、必須チェック `ci`）。非公開の Free プランでは作れないので、警告だけ出す
- clone して、更新を取り込むための remote `harness` を足す

gh がないときは、GitHub で空のリポジトリ（README やライセンスは付けない）を先に作ってから、`REPO` に URL を書いて実行し、最後に表示される設定（既定ブランチ、マージ方式、ルールセット）を Settings で行います。

</details>

#### 2. Claude Code を起動する

```sh
cd ../my-app               # REPO_DIR を書いたときは、その場所
claude
```

`my-app` の直下で、`develop` にいる状態で起動します（サブディレクトリで起動すると hooks が動きません）。初回はログイン、フォルダを信頼するかの確認、Context7（MCP サーバー）の使用の承認が出ます。続けて 2.2 の `/kickoff` に進みます。

<details>
<summary>既存のリポジトリにハーネスを入れるとき</summary>

`npm run create-repo` は使えません。`.claude/`、`docs/`、`.github/`、`CLAUDE.md`、`.mcp.json`、`.gitignore`、`package.json`、`.env.sample` をリポジトリの直下にコピーし（同名のファイルは上書きしないよう注意）、`main` と `develop` を用意して、上の「スクリプトがしていること」の設定を GitHub の画面で行います。この場合は 2.11 の更新の取り込みも使えません（ハーネスと履歴を共有しないため）。

</details>

### 2.2 新しいプロジェクトを始める

```text
/kickoff → /plan-spec → （要件ごとに）/plan-spec REQ-xxx → （設計ごとに）/implement-tdd DES-xxx
```

1. `/kickoff` を実行します。`docs/project/` に「概要」（overview.md）と「技術・環境」（tech.md）のテンプレートがコピーされます。
2. 各見出しの `（未記入）` を自分の言葉で書き換えます。全部埋めなくても構いません。残った空欄は Claude が1問ずつ質問して埋めます。記入済みの見出しは、不足や矛盾の指摘だけを受けます。「未定」「わからない」も有効な回答です。技術・環境の「開発コマンド」（テスト、リント、フォーマット、ビルド）は必ず決めます。
3. Claude が示す内容（用語集の英語名を含む）を**承認**します。承認の後、Claude が概要と技術・環境をもとに、直下の `README.md` をプロジェクトの説明（概要、環境構築、起動方法、この説明へのリンク）に書き換えます。
4. `/plan-spec` を実行します。Claude が要件（REQ）と実装順を決め、AI レビューを通します。要件一覧・実装順・各 REQ の「判断」を**承認**します。
5. 実装順に `/plan-spec REQ-001` などで要件ごとに設計（DES）とテスト項目を作ります。設計と各 DES の「判断」を**承認**します。
6. `/implement-tdd DES-001` などで設計1つずつ実装します。テストの作成 → Red の確認 → テストのレビュー → テストの凍結 → 実装 → 整理 → コードのレビューまでを Claude が進めます。最後に示される人間確認の項目を**確認**します。
7. 全要件が終わるまで 5〜6 を繰り返します。

### 2.3 機能を追加する・仕様を変える・機能を削除する

開発開始の後に、新しい要件の追加、既存の受け入れ基準の変更、機能の削除、構成（architecture.md）の変更のどれかを伴う場合の手順です（WF-20）。

```text
/plan-spec change <変更内容> → （影響する要件ごとに）/plan-spec REQ-xxx → （設計ごとに）/implement-tdd DES-xxx
```

1. `/plan-spec change <変更内容>` を実行します（例: `/plan-spec change 割り勘の端数を切り上げではなく指定した人が負担できるようにする`）。
2. Claude が影響一覧（変える REQ・DES・テスト・資料）を作り、REQ を追加・改訂・削除して実装順を決めます。目的やスコープが変わる場合だけ、overview.md の改訂点を質問されます。
3. 影響一覧・実装順・各 REQ の「判断」を**承認**します。
4. 実装順に `/plan-spec REQ-xxx` で設計し、**承認**します。既存の振る舞いを変える場合は、新しい DES を足さずに既存の DES が改訂されます。
5. `/implement-tdd DES-xxx` で実装し、人間確認の項目を**確認**します。

### 2.4 小さな不具合や文言・設定を直す

次をすべて満たす変更が対象です（WF-17）。1つでも外れる場合は 2.3 の手順を使います。

- 新しい要件の追加や受け入れ基準の変更がない
- 公開インタフェース（DES のインタフェース欄に載るもの）の追加・変更がない
- 作成・変更するファイルが3つ以下

```text
/quick-change <変更内容>
```

1. `/quick-change <変更内容>` を実行します（例: `/quick-change 合計が0円のときにエラーになる不具合を直す`）。
2. Claude が探索して上の3条件を判定します。不具合なら再現テストを書いて失敗を確認し、テストを凍結してから修正します。テスト・リント・ビルドとコードのレビューまでを Claude が進めます。
3. 最後に示される変更内容・レビュー結果・人間確認の点を**確認**します。

### 2.5 ドキュメントだけを直す

ドキュメント専用の Skill はなく、`/quick-change` の「資料だけの変更」の手順を使います（WF-18）。テストは省き、計画書の AI レビュー（plan-reviewer）だけを通します。

```text
/quick-change <変更内容>
```

直す資料によって、入口が変わります。

| 直す内容 | 入口 |
|---|---|
| 誤字、表現、説明の補足など、意味を変えない修正（REQ・DES・architecture.md・用語集・tech.md など） | `/quick-change` |
| REQ の受け入れ基準の変更、要件の追加・削除、overview.md の目的・スコープ・成功基準の変更、architecture.md の構成の変更 | `/plan-spec change`（2.3） |
| DES の公開インタフェース（インタフェース欄）の変更 | `/plan-spec change`（2.3。WF-17 の (2) から外れるため） |

`docs/guidelines/`（全プロジェクト共通のルール）を直すときも `/quick-change` を使えます。ルール ID を変えたり消したりしたときは、`/refactor` の機械判定（`audit.sh`）で参照切れがないことを確かめます。

### 2.6 中断した作業を再開する

`claude` をリポジトリの直下で起動すると、session-start hook が進行中・中断中のタスク記録（`docs/project/tasks/`）の「現在のフェーズ」と「次の一手」を Claude に渡します。「続きをやって」と頼めば、その位置から再開します。質問の途中だった場合は、未回答の質問から再開します。

### 2.7 進捗・次の作業・残作業を確かめる

```text
/progress
```

「今どこまで進んだ？」と聞くだけでも使われます。Claude が要件・設計・タスク記録の状態を集計し、現在地、次の作業（Skill と引数）、進行中のタスク、残作業、人間の対応待ちを報告します。ファイルは変更しません。報告の後に「続けて」と言えば、進行中のタスクの「次の一手」から再開します。報告は資料とタスク記録だけを根拠にします（WF-22）。

### 2.8 コード全体を整理し、資料どうしの齟齬を直す

```text
/refactor [点検するディレクトリ]
```

差分のレビューでは見えない、実装や変更を重ねるうちに積み重なる問題を、リポジトリ全体から探して直します。ファイルをまたぐ重複、少しずつの肥大、名前の揺れ、設計とコードのずれ、ID の参照切れなどが対象です。観点の正本は [`docs/guidelines/refactoring.md`](guidelines/refactoring.md) です。

1. `/refactor` を実行します。Claude が機械で判定できる観点を `.claude/scripts/audit.sh` で、意味の判断が要る観点を code-auditor と docs-auditor（サブエージェント）で調べます。
2. 指摘は「自動修正」「変更要求の候補」「任意（P2）」に分類されます。診断結果と修正計画を**承認**し、任意の指摘から直すものを選びます。
3. Claude が振る舞いを変えない修正だけを直します。テストファイルは変えず、全テストが成功したままにします。
4. 直した内容と変更要求の候補を**確認**します。仕様に関わる候補は `/plan-spec change`（2.3）で1件ずつ進めます。

実行するのは人間の指示があったときだけです。前回の点検の後に実装のタスクが5件終わったとき、または全要件の実装が終わったときに、Claude が実行を提案します（WF-25）。

### 2.9 リリースする

```text
/release [版番号]
```

全要件の実装が終わったとき（または任意の時点で指示したとき）に、`develop` の内容を `main` に入れます（GIT-50〜52）。

1. `/release` を実行します。Claude が、進行中のタスクや未マージの作業ブランチがないこと、テスト・リント・ビルドが通ることを確かめます。
2. Claude が版番号を決めます。初回は `v1.0.0`、2回目以降はコミットの種類（GIT-12）から、互換性を壊す変更があればメジャー、機能の追加があればマイナー、それ以外はパッチを上げます。
3. `develop` → `main` の PR と承認パケットが示されるので、**承認**します。
4. Claude がマージし、タグを付けてリリースノートを作ります。

### 2.10 リリース済みの本番の不具合を急いで直す（hotfix）

```text
/quick-change hotfix <変更内容>
```

リリース済みの `main` に緊急の修正が必要で、`develop` に未リリースの変更がある場合だけ使います（GIT-60）。それ以外は 2.4 の通常の手順で直します。

1. Claude が最新のタグから `hotfix/v<次のパッチ版>` を作り、2.4 と同じ手順（再現テスト → 凍結 → 修正 → レビュー）で直します。
2. 承認パケットで**確認**します。
3. Claude が `main` にマージしてタグとリリースノートを作り、同じ修正を `develop` にも入れます（GIT-61）。

### 2.11 ハーネスの更新を取り込む

**何のため**：`my-app` は、作った時点のハーネスの写しです。そのあとハーネス（このリポジトリ）に機能の追加や修正が入っても、`my-app` には自動では反映されません。この手順で、ハーネスの新しい版を `my-app` に取り込みます。`docs/project/` やコードはハーネスにないので、消えたり変わったりしません。

**いつ**：ハーネスの `main` が新しくなったときです（ハーネスの更新は `main` に区切りよくまとめて入ります）。更新がなければ、実行しても何もしません。

**やること**：`my-app` の中で実行し、できた PR をマージします。

```sh
npm run update-harness
```

スクリプトは次の順に進みます。

1. ハーネスの最新の `main` を取ってくる
2. `develop` から取り込み用のブランチ `feature/harness-update` を作り、そこにハーネスの `main` を merge する
3. push して、`develop` への下書き PR を作る

PR で変わったファイル（`.claude/` や `CLAUDE.md` など）を確かめ、**マージコミット** でマージします（GIT-23）。マージコミットが「どこまで取り込んだか」の印になり、次回はそれより後の更新だけが入ります。

- 衝突したときは、スクリプトが途中で止まり、衝突したファイルと続け方を表示します。衝突するのは `CLAUDE.md`、`package.json`、`/kickoff` が書いた `ci.yml` の印の間などを `my-app` の側で直していたときだけです。
- 直下の `README.md` は、`.gitattributes` の `merge=ours` により、`my-app` の側（プロジェクトの説明）がそのまま残ります（スクリプトが `merge.ours.driver` を設定します）。ハーネスの説明の更新は `docs/harness.md` に入ります。

## 3. フォルダ・ファイル構成

docs 内の各資料に何を書くか、いつ読むかは [`docs/README.md`](README.md) にあります。

```text
.
├── README.md                  # 入口。ハーネスでは本ファイルへの案内だけ。作ったリポジトリでは /kickoff がプロジェクトの説明に書き換える
├── CLAUDE.md                  # Claude が毎セッション読む指示。落とし穴と参照先だけ
├── .mcp.json                  # 共有する MCP サーバー。Context7（ライブラリの最新ドキュメント）だけ
├── .gitignore                 # レビュー用の差分ファイル（.claude/review/）と .env を除外
├── .gitattributes             # 更新の取り込みで、直下の README.md は作ったリポジトリの側を残す（merge=ours）
├── package.json               # npm run create-repo / update-harness の入口だけ（依存パッケージはない）
├── .env.sample                # npm run create-repo の設定のひな形（.env に写して書く）
├── .github/
│   ├── pull_request_template.md  # PR 本文の形
│   └── workflows/ci.yml       # CI。ci.sh を実行するだけ
├── .claude/
│   ├── settings.json          # 権限、hooks、応答言語（日本語）
│   ├── hooks/                 # session-start / freeze-guard / branch-guard / format と共通関数 lib.sh
│   ├── scripts/               # 定型の操作（task.sh、branch.sh、ci.sh、progress.sh、audit.sh、create-repo.sh、update-harness.sh。使い方は各スクリプトの冒頭）
│   ├── agents/                # レビュー（plan / test / code-reviewer）と全体点検（code / docs-auditor）のサブエージェント
│   └── skills/                # 作業の手順。/kickoff /plan-spec /implement-tdd /review-loop /quick-change /progress /refactor /release
└── docs/
    ├── README.md              # docs の索引。各資料の内容と「いつ読むか」
    ├── harness.md             # 本ファイル。ハーネスの人間向けの説明
    ├── guidelines/            # 全プロジェクト共通の基準（ルール ID 付き）とテンプレート
    └── project/               # このプロジェクト固有の資料（概要、技術・環境、要件、設計、テスト項目、ADR、タスク記録など）
```

## 4. 仕組み

### 4.1 人間の役割

人間が内容を書くのは、開発開始のテンプレート記入までです。それ以降は承認と確認だけです（WF-15・16）。

| 人間の作業 | タイミング |
|---|---|
| 承認 | 開発開始の完了時、要件一覧の完了時、変更要求の計画の完了時、各要件の設計の完了時、要件・設計を戻すとき、リリースの前 |
| 確認 | 設計の人間確認の項目、レビューで残った指摘・保留した指摘、軽微な変更の完了時 |
| PR のマージの許可 | 作業ブランチの範囲の最後の承認・確認の後に、Claude がマージするときの確認プロンプト |

承認と確認の依頼は「承認パケット」で示されます（GIT-30）。15行以内の要約と、その承認の範囲だけの GitHub の差分リンクです。差分の行に GitHub でコメントすると、Claude が返答の後に読んで指摘として扱います。承認そのものはチャットで答えます。要件と設計の判断は Claude が推奨案で決め、各 REQ・DES の「判断」セクションに選択肢と理由を残します。

### 4.2 役割の分担

| 仕組み | 役割 |
|---|---|
| `docs/guidelines/` | 基準（ルール、観点、定義）の正本。各ルールに ID（例: `TEST-03`）を振り、レビューの指摘には違反したルール ID を書く |
| Skills | 作業の手順の正本。手順の最初で、必要な guidelines を読む |
| agents | 役割と読む範囲。毎回新しいコンテキストで起動し、判定に使う guidelines だけを読む |
| hooks | 機械的な強制。読まなくても守られる部分を担当する |
| `.claude/scripts/` | 定型の操作（TASK の作成と更新、ブランチと PR、CI の確認、進捗の集計、全体点検の機械判定） |
| CLAUDE.md | 落とし穴と参照先だけ（`@` インポートはしない） |

### 4.3 hooks

`.claude/settings.json` に4つの hook を設定しています。スクリプトは `.claude/hooks/` にあり、`claude` をリポジトリの直下で起動したときだけ動きます。

| hook | タイミング | 内容 |
|---|---|---|
| session-start | セッション開始、再開、`/clear`、圧縮の後 | 進行中・中断中の TASK の「現在のフェーズ」と「次の一手」を Claude に渡す |
| freeze-guard | ファイル編集と Bash の実行の直前 | 凍結したテストファイルへの書き込みを止める（Bash はコマンド文字列で判定するため、見抜けない分はコードのレビューで検出する） |
| branch-guard | Bash の実行の直前 | `main` と `develop` への直接のコミット・マージ・プッシュを止める（GIT-02） |
| format | ファイル編集の直後 | 技術・環境の資料にあるフォーマットコマンドで、編集したファイルを整形する。未記入か「なし」なら何もしない |

### 4.4 権限

権限モードは指定せず、Claude Code の既定に任せます。`.claude/settings.json` には次の3種類のルールだけを書きます。

| 種類 | 対象 |
|---|---|
| 禁止（deny） | `.env` 系ファイルの読み取り（`.env.sample` は除く）、`git push` の強制上書き、`git rebase`、`git commit --amend`、`gh repo delete` |
| 確認（ask） | `gh pr merge`、`branch.sh merge` |
| 許可（allow） | `git push`（`main`・`develop` へのプッシュは branch-guard が止める）、`ci.sh`、`gh pr checks`、Context7 のツール |

### 4.5 外部サービス

- GitHub は `gh` CLI で操作します。GitHub の MCP サーバーは使いません。
- MCP サーバーは `.mcp.json` の Context7（ライブラリやフレームワークの最新ドキュメント）だけです。API キーはなくても使えます。
- Web 検索とページの取得は、Claude Code 組み込みの WebSearch / WebFetch を使います。

### 4.6 Git と CI

正本は [`docs/guidelines/git.md`](guidelines/git.md) です。

- **ブランチ**: 常設は `main`（リリース済み）と `develop`（統合先）。作業は `develop` から切る `feature/` で行い、リリース済みの本番の緊急修正だけ `main` から `hotfix/` を切ります。1つの要件の設計と全実装で1ブランチ・1 PR です。
- **コミットとマージ**: 形は `feat(DES-003): 日本語の要約` です。履歴は書き換えず、マージはすべてマージコミットです。
- **CI**: GitHub Actions が、下書きでない PR と `main`・`develop` へのプッシュで `.claude/scripts/ci.sh` を実行します。ci.sh は技術・環境の資料の開発コマンドを順に実行します。Claude は承認を頼む前とマージの前に CI の成功を確かめます。
- **イシュー**: 使いません。依頼はチャットで受け、記録はタスク記録だけにします。
- **GitHub を使わない場合**: スクリプトが手元でのマージ、`git diff --stat`、手元の ci.sh に切り替えます（GIT-33）。

## 5. Claude とのやり取り

- 応答言語は日本語に固定します（`.claude/settings.json` の `language`）。
- Claude からの質問は、1回に1問ずつ提示されます。質問が2問以上になるときは、最初に「全部で何問あり、それぞれ何を聞くか」の一覧が示され、各質問に `2/5` のような通し番号が付きます（PLAN-07）。
- 応答は「である調」で書きます（規則の正本は CLAUDE.md）。
