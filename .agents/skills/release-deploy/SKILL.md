---
name: release-deploy
description: 「雨つづり。」で開発機能をリリース、gitを更新するときに使用する。
---

# release-deploy

## Purpose

「雨つづり。」Flutter Web版を安全にrelease / tag / push / Firebase Hosting deployするための手順を統一する。

release時に、

- 別Repositoryでコマンドを実行する
- 未検証コードをdeployする
- 意図しない差分を含める
- build失敗を無視する
- Firebase設定を誤る
- tag状態を推測する

ことを防ぐ。

---

## When to use

以下の依頼で使用する。

- releaseしたい
- tagを付けたい
- pushしたい
- Firebase deployしたい
- versionを公開したい
- 身内テスト用Web版を更新したい
- 「tag / push / deployして」と依頼された

以下の場合は使用しない。

- 通常の実装
- Audit
- 開発途中のWidget testのみ
- Asset制作のみ

---

## Repository

対象Repository：

```text
C:\Users\osjtm\Develop\ame_tsuzuri
```

作業開始時に必ず現在directoryとGit repositoryを確認する。

別Repositoryである場合はrelease作業を進めない。

過去に別RepositoryでFirebase関連確認を実行したことがあるため、cwd確認を省略しない。

---

## Firebase project

Firebase project：

```text
ametsuzuri-prototype
```

公開URL：

```text
https://ametsuzuri-prototype.web.app/
```

`.firebaserc` のdefault projectが `ametsuzuri-prototype` であることを確認する。

`firebase.json` は原則として現在設定をそのまま使用する。

releaseのためだけにFirebase設定を変更しない。

---

## Release principles

1. deploy前に必ずGit差分を確認する
2. 全テスト成功前にdeployしない
3. `flutter analyze` エラーを無視しない
4. `flutter build web` 失敗時はdeployしない
5. `git diff --check` エラーを無視しない
6. 意図しない差分を勝手に修正しない
7. 既存の無関係な変更を削除・revertしない
8. Firebase設定を都合よく書き換えて通さない
9. tagの存在・version状態を推測しない
10. command失敗時に同じ操作を原因不明のまま反復しない

---

## Step 1. Repository確認

最初に以下を確認する。

```powershell
Get-Location
git status
git branch --show-current
git remote -v
```

確認ポイント：

- `ame_tsuzuri` repositoryである
- 想定branchである
- 意図しない変更がない
- untracked fileがないか
- remoteが想定どおり

既存の無関係な差分がある場合は削除しない。

release対象との差分を整理して報告する。

---

## Step 2. Version確認

ユーザーが指定したversionを使用する。

例：

```text
v0.5.1
```

tagが存在するか確認する。

```powershell
git tag --list
```

または対象だけ確認する。

```powershell
git tag --list "v0.5.1"
```

tag状態を推測しない。

既存tagと重複する場合は新しいtagを勝手に作り直さない。

---

## Step 3. Diff確認

以下を確認する。

```powershell
git status --short
git diff
```

必要に応じて、

```powershell
git diff --stat
```

も使用する。

確認ポイント：

- 変更ファイルが想定どおり
- Provider / Repository / YAML / Asset等に意図しない変更がない
- debug codeが残っていない
- temporary fileがない
- test更新が必要なのに欠けていない

---

## Step 4. Targeted test

変更内容に対応する個別testがある場合は、先に実行する。

例：

```powershell
flutter test test/features/room/presentation/room_page_test.dart
```

関連WidgetやProviderを変更している場合は、そのtestも実行する。

個別testが失敗した状態で全testやdeployへ進まない。

---

## Step 5. Analyze

実行：

```powershell
flutter analyze
```

成功条件：

```text
No issues found
```

error / warning / lintが新規に出た場合は内容を確認する。

既存問題か新規問題かを区別する。

---

## Step 6. Full test

実行：

```powershell
flutter test
```

全test成功を確認する。

既知のnonfatal warningがある場合は、

- test自体が成功していること
- 今回変更による新規warningではないこと

を確認する。

失敗を無視してreleaseしない。

---

## Step 7. Diff check

実行：

```powershell
git diff --check
```

以下がないことを確認する。

- trailing whitespace
- whitespace error

LF / CRLFに関する既知warningのみの場合は、内容を確認して報告する。

release目的だけでline endingを大規模変更しない。

---

## Step 8. Web build

実行：

```powershell
flutter build web
```

成功を確認する。

Wasm dry run等の警告・情報がある場合は、build成功かどうかを区別する。

`build/web` が生成されていることを確認する。

---

## Step 9. Firebase configuration check

確認：

```powershell
firebase use
```

必要に応じて：

```powershell
firebase projects:list
```

確認項目：

- current projectが `ametsuzuri-prototype`
- `firebase.json` のhosting publicが `build/web`
- 想定外のtarget / siteを使用していない

設定に問題がある場合は、勝手に変更せず報告する。

---

## NODE_USE_SYSTEM_CA

Windows環境でFirebase CLIの証明書関連問題が発生した場合のみ、

現在PowerShellプロセス限定で以下を使用してよい。

```powershell
$env:NODE_USE_SYSTEM_CA='1'
```

永続環境変数として設定しない。

問題が発生していない場合は設定しない。

---

## Step 10. Commit

ユーザーからcommitを含む依頼がある場合のみ行う。

commit前に再度：

```powershell
git status
git diff --check
```

を確認する。

commit messageはversion内容を簡潔に表す。

例：

```text
Polish room rearrangement UI
```

既存commitをrewriteしない。

`--amend`、rebase、force pushは明示依頼がない限り使用しない。

---

## Step 11. Tag

ユーザーからtag作成を依頼されている場合のみ行う。

例：

```powershell
git tag v0.5.1
```

tag作成前に、

```powershell
git tag --list "v0.5.1"
```

で重複確認する。

既存tagがある場合は上書きしない。

annotated tagを使用する運用が現在明示されていない場合、既存repositoryのtag形式に合わせる。

---

## Step 12. Push

通常はまずcommitをpushする。

例：

```powershell
git push
```

tagを作成した場合：

```powershell
git push origin v0.5.1
```

または既存運用に合わせる。

force pushは禁止。

push後にremote反映を確認する。

---

## Step 13. Firebase deploy

ここまでの検証がすべて成功した場合のみ実行する。

```powershell
firebase deploy --only hosting
```

deploy失敗時は、

- 原因を確認
- 設定変更が必要か確認
- 同じdeployを原因不明のまま繰り返さない

---

## Step 14. Published site check

deploy後は公開URLを確認する。

```text
https://ametsuzuri-prototype.web.app/
```

最低限確認する。

- ページが開く
- bootstrap失敗がない
- console errorがない
- 今回変更したUI / 機能が反映されている
- 古いキャッシュ状態ではない

必要に応じてhard reloadを使用してよいが、

ユーザー側へ毎回cache clearを要求する前提にはしない。

---

## Cache policy

過去にFirebase Hosting上で旧buildが残って見える問題があった。

現在はHosting側で、

```text
Cache-Control: no-cache, max-age=0, must-revalidate
```

を利用する構成を前提とする。

release時に理由なくcache設定を変更しない。

---

## Stop conditions

以下の場合はrelease / deployを停止する。

- 別Repositoryだった
- `flutter analyze` 失敗
- `flutter test` 失敗
- `git diff --check` 失敗
- `flutter build web` 失敗
- Firebase projectが不明
- 意図しない差分がある
- tag衝突
- Firebase CLIが原因不明で繰り返し失敗
- deploy対象buildが最新か確認できない

停止時はAGENTS.mdの「Unexpected blockers」に従って報告する。

---

## Do not do

明示依頼がない限り以下を行わない。

- force push
- tag上書き
- rebase
- amend
- reset --hard
- checkoutでユーザー変更を消す
- Firebase project再設定
- Firebase Hosting site追加
- target追加
- package upgrade
- Flutter upgrade
- Node upgrade
- line ending一括変換
- unrelated refactor
- debug目的の設定変更をcommit

---

## Final report

release完了後は以下を報告する。

1. 対象version
2. 対象branch
3. 変更ファイル
4. `git status`
5. 実行した個別test
6. `flutter analyze`
7. `flutter test`
8. `git diff --check`
9. `flutter build web`
10. commit
11. tag
12. push
13. Firebase deploy
14. 公開URL
15. 公開後確認
16. warning / known issue
17. 残っている未コミット差分

成功していない項目を「成功」と書かない。

実際に実行したcommandだけを報告する。

---

## Completion criteria

release完了とは、

- 対象Repository確認済み
- 意図した差分のみ
- analyze成功
- test成功
- diff check成功
- web build成功
- 必要なcommit / tag / push完了
- Firebase Hosting deploy成功
- 公開版確認済み

の状態を指す。