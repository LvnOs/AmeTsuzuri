---
name: letter-content-change
description: 「雨つづり。」でLetterコンテンツを追加・修整するときに使用する。
---

# letter-content-change

## Purpose

「雨つづり。」のLetterコンテンツを安全に追加・修正するための手順を統一する。

このSkillでは、

- Letter本文
- `letters.yaml`
- 季節
- 天気
- 優先順位
- tutorial Letter
- 既読・配達済み判定
- Repository読込
- テスト

との整合を確認しながら作業する。

LetterはCoreコンテンツなので、機能追加versionとは独立して継続的に増やせる前提で扱う。

---

## When to use

以下の依頼で使用する。

- Letterを追加したい
- 季節Letterを増やしたい
- 既存Letter本文を修正したい
- `letters.yaml` を更新したい
- Letterの季節や天気条件を変更したい
- LetterのtitleやMarkdownを整理したい
- tutorial Letterを修正したい
- Letter一覧を確認したい
- Letter追加に伴うテストを更新したい

以下の場合は原則使用しない。

- Letter配達ロジックそのものを変更する
- Bookshelf UIを変更する
- Weather機能を実装する
- Letter到着animationを変更する
- 雫報酬システムを変更する

これらは通常の実装タスクまたはfeature-auditを使用する。

---

## Core principles

Letter変更では以下を優先する。

1. 既存Letterのフォーマットを維持する
2. YAMLとMarkdownの整合を保つ
3. 既存IDを不用意に変更しない
4. 既存Letterの順序を理由なく並べ替えない
5. tutorial Letterを通常Letterと同じ扱いにしない
6. 季節・天気条件を現在実装に合わせる
7. 配達済み・既読判定との互換性を壊さない
8. 同じLetterへの報酬重複を起こさない
9. 本文だけの変更で不要なDartコードを触らない
10. Letter追加を機能versionの大規模変更に結び付けない

---

## Current Letter structure

Letterコンテンツは主に以下で管理される。

```text
assets/data/letters.yaml
assets/letters/*.md
```

具体的なfield名・保存形式・条件については、
このSkillの記述より**現在の実装・テスト・YAML**を正とする。

作業開始時に、対象Letter周辺の現在フォーマットを確認する。

---

## Important invariants

以下は基本的に維持する。

- 1日につき配達されるLetterは最大1通
- 初回はtutorial Letterを優先する
- 通常Letterは未読状態、季節、天気、YAML上の優先順位等から選択される
- 同じLetterの報酬を重複取得させない
- 配達済みだが未読のLetterを再配達しない
- tutorial Letterは通常の季節Letter拡充とは分離する

Letter追加時に配達ロジックを変更する必要は原則ない。

---

## Workflow

### Step 1. 現在のLetter一覧を確認

まず `letters.yaml` と対象Markdownを確認する。

確認するもの：

- 現在のID
- title
- season
- weather
- priority
- body file
- 既存並び順
- 同系統のLetter
- tutorialとの重複

新規Letterを追加する前に、同じ題材や似たtitleがすでにないか確認する。

---

### Step 2. 既存フォーマットを確認

新しい形式を勝手に作らない。

対象に近い既存Letterを1〜3件確認し、

- YAMLの書き方
- Markdown本文の構成
- 改行
- titleの扱い
- 文体
- 長さ
- 季節感
- 雨との関係

を合わせる。

---

### Step 3. Letter IDを決める

既存の命名規則に従う。

既存IDを変更すると、

- 既読状態
- 配達済み状態
- 報酬取得状態

との互換性に影響する可能性があるため、
既存LetterのIDは原則変更しない。

新規Letterは既存規則に沿って一意のIDを付ける。

---

### Step 4. YAML entryを追加する

`letters.yaml` に新規entryを追加する。

確認する項目：

- id
- title
- body file
- season
- weather
- priority
- 公開条件
- その他現在schema上必要なfield

field名は現在のYAMLを正とする。

不要なfield追加やschema変更は行わない。

---

## Season policy

季節は現在実装の `SeasonType` に合わせる。

例：

- spring
- summer
- autumn
- winter
- any

実際の文字列表現は現在のYAMLを確認する。

季節Letterとして追加する場合は、
内容とseason指定が一致していることを確認する。

例：

- 蛍 → summer
- 紅葉 → autumn
- 霜 → winter
- 若葉 → spring

ただし題材だけで機械的に決めず、
本文の雰囲気と現在仕様を優先する。

---

## Weather policy

Weather条件は現在実装とYAMLを確認して設定する。

雨専用・晴れ専用・天候非依存などが存在する場合、
既存表現に合わせる。

新しいWeather typeはLetter追加だけを理由に追加しない。

---

## Priority policy

priorityは既存配達ロジックへ影響する。

新規Letter追加時に理由なくpriority体系を変更しない。

既存Letterとの相対順位を確認する。

複数Letterのpriorityを一括変更する場合は、
単純なコンテンツ追加ではなく仕様変更として扱う。

---

## Markdown body

Markdown本文は `assets/letters/` 以下に置く。

既存命名規則に合わせる。

例：

```text
assets/letters/<letter-file>.md
```

新規ファイル名は、
IDまたは現在の命名方式に合わせる。

---

## Title handling

現在のLetter表示では、
YAML titleとMarkdown先頭H1の重複を避ける処理がある。

そのため、新規Markdownでは原則として、

**本文中にtitleのH1を重複して書かない**

方を優先する。

既存コンテンツ形式との整合上H1が必要な場合は、
現在のLetterPage処理で問題なく表示されるか確認する。

以下のような二重表示は避ける。

```text
YAML title
↓
# 同じtitle
↓
本文
```

---

## Writing style

Letter本文は「雨つづり。」の世界観に合わせる。

基本：

- 静か
- 押し付けない
- 説明しすぎない
- 雨の日の小さな発見
- 季節の気配
- 日常の延長
- 読後に少し余白が残る

避ける：

- 強いゲーム的表現
- ミッション感
- 過度な励まし
- 説教
- 情報量過多
- 長すぎる説明
- 世界観から離れた現代的UI語彙

既存Letterの長さと文体を基準にする。

---

## Tutorial Letter

tutorial Letterは通常Letterと分離して扱う。

変更時は以下を確認する。

- 初回配達優先
- 雫説明
- Furniture説明
- Catalog導線
- 本棚導線
- 現在tutorial UIとの整合

tutorial Letterだけ変更して、
tutorial UIやstateが古い説明のまま残らないようにする。

逆にtutorial UI変更が必要な場合は、
Letterコンテンツ変更だけで済ませず別タスクとして扱う。

---

## Content duplication check

新規Letter追加時は、
既存Letterと以下が重複していないか確認する。

- title
- 主題
- 季節モチーフ
- 結末
- 同じ比喩
- 同じ風景
- 同じ小道具

完全に異なる必要はないが、
連続して読んだときに同じLetterに感じないことを重視する。

---

## Ordering

`letters.yaml` の現在の並び順に意味がある場合がある。

理由なく以下を行わない。

- 全体sort
- ID順への並び替え
- title順への並び替え
- seasonごとの全面再配置

新規Letterは現在の整理方針に沿った位置へ追加する。

---

## File consistency

新規Letter追加時は以下を必ず確認する。

- YAMLのbody fileが存在する
- Markdown filenameがYAMLと一致
- typoがない
- 重複IDがない
- 重複pathがない
- season値が有効
- weather値が有効
- priority形式が有効

---

## Pubspec / Asset registration

現在 `assets/letters/` がdirectory単位で登録されている場合、
Letter追加だけで `pubspec.yaml` を変更しない。

現在のasset登録方式を確認する。

個別登録方式の場合のみ必要な追加を行う。

---

## Testing

Letter追加・修正後は、変更内容に対応するテストを確認する。

最低限：

- Letter repository読込
- YAML parse
- Markdown読込
- ID重複
- body file存在
- season / weather filter
- tutorial優先
- 未読判定
- 配達済み除外
- 1日1通
- LetterPage表示

既存テストが件数を固定している場合は、
新規Letter追加に合わせて期待値を更新する。

単純に「件数が変わったから」だけで広範囲のtestを書き換えない。

---

## Letter count tests

季節ごとの件数を固定しているテストがある場合は、
追加後の正しい件数へ更新する。

例：

```text
spring: 10 -> 11
```

ただし、
新規Letter追加に関係しない件数expectをまとめて変更しない。

---

## Delivery regression

Letter追加だけでも、
配達選択へ影響する可能性がある。

必要に応じて以下を確認する。

- tutorial Letterが初回優先される
- 既読Letterを選ばない
- 配達済み未読Letterを再配達しない
- season対象外を選ばない
- weather対象外を選ばない
- priority順が意図どおり
- 候補なし時の挙動が変わっていない

---

## Bookshelf regression

Bookshelfは既読Letterを表示する。

Letter追加時にBookshelfコード変更は原則不要。

ただし以下を確認する。

- title表示
- season filter
- 日付順
- LetterPage遷移
- body表示

---

## Validation

変更範囲に対応する個別testを先に実行する。

その後、原則として：

```powershell
flutter analyze
flutter test
git diff --check
```

を実行する。

Web buildが必要なrelease前作業では、
`release-deploy` Skillに従う。

---

## Recommended file scope

Letter本文追加だけなら、通常変更するのは：

```text
assets/data/letters.yaml
assets/letters/<new-letter>.md
```

必要に応じて：

```text
test/...
```

のみ。

以下は原則変更しない。

- Provider
- Repository
- SharedPreferences
- RoomPage
- Catalog
- Furniture
- Weather implementation
- Season implementation

Letter追加だけでDartコード変更が必要になった場合は、
理由を明示する。

---

## Do not do

Letter追加だけを理由に以下を行わない。

- Letter schema再設計
- Repository大規模refactor
- 新Provider追加
- 新SharedPreferences key追加
- tutorial state変更
- Weather type追加
- Season type追加
- Bookshelf再設計
- Letter arrival animation変更
- 全Letterの文体一括修正
- 全YAML並び替え
- 既存ID変更

---

## Required report

作業後は以下を報告する。

1. 追加・変更したLetter
2. 変更したファイル
3. YAML変更内容
4. Markdown変更内容
5. season
6. weather
7. priority
8. 既存Letterとの重複確認
9. tutorialへの影響
10. 保存データへの影響
11. 配達ロジックへの影響
12. Bookshelfへの影響
13. 更新したテスト
14. 実行した検証コマンド
15. 検証結果
16. 今回変更していないもの

---

## Completion criteria

Letter変更完了とは、

- YAMLとMarkdownが一致している
- IDが一意
- season / weatherが有効
- title表示が崩れない
- tutorialへの意図しない影響がない
- 既存配達ロジックを壊していない
- 必要なテストが更新されている
- analyze / testが成功している

状態を指す。