---
name: feature-audit
description: 「雨つづり。」で新機能、UI改善、仕様変更、次versionの候補を実装する前に、現在実装を調査し、複数案を比較してMVPとして推奨する1案へ絞るときに使用する。
---

# feature-audit

## Purpose

「雨つづり。」で新機能・改善案・UI変更を実装する前に、現在実装を確認し、候補比較とリスク整理を行ったうえで、MVPとして妥当な1案へ絞り込む。

このSkillは**実装前Audit専用**とする。

原則として、このSkill実行中はコード・Asset・YAML・保存データを変更しない。

---

## When to use

以下のような依頼で使用する。

- 新しい機能を追加したい
- 次versionのテーマを決めたい
- 複数の実装案を比較したい
- UIの位置・形式・導線を比較したい
- 既存仕様を変更すべきか判断したい
- 実装前に影響範囲を調査したい
- 「まずAuditして」と依頼された
- 実装する前に現在コードとの整合を確認したい

以下の場合は原則使用しない。

- 仕様がすでにFIX済みで、単純に実装するだけ
- 軽微な文言修正
- 明確な不具合の修正
- 単純なAsset差し替え
- release / deploy作業

---

## Core principles

Auditでは以下を優先する。

1. 現在の実装を正確に把握する
2. 既存設計をできるだけ維持する
3. MVP・prototype完成速度を優先する
4. 不要なProvider、Repository、状態、依存を追加しない
5. 保存形式や既存ユーザーデータへの影響を最小化する
6. UIでは世界観と初見理解を両立する
7. 新機能の数ではなく、ユーザー体験上の変化を評価する
8. 過去に決定済みの仕様と矛盾しないか確認する
9. 実装可能性だけでなく、テスト・運用・撤退しやすさも評価する
10. 最終的には複数案を残さず、原則1案を推奨する

---

## Audit workflow

### Step 1. 現在実装の調査

まず対象機能に関係する現在コード・テスト・YAML・Asset・保存処理を確認する。

必要な範囲だけ読む。

最初からRepository全体を広く読み込まない。

確認対象例：

- 対象Page / Widget
- 関連Provider
- 関連Repository
- Model
- YAML / Markdown
- SharedPreferences
- Widget test
- Provider / Repository test
- Asset構成
- `pubspec.yaml`
- 既存tutorialとの関係
- Room Stack / hit test
- Browser固有挙動

---

### Step 2. 現在仕様を整理する

推測ではなく、現在コードを根拠に整理する。

以下を明確にする。

- 現在何ができるか
- 現在どこで状態を持っているか
- 保存形式
- UI導線
- 既存制約
- 再利用可能な処理
- 既知の未使用項目
- 変更すると壊れやすい箇所

具体的な配信条件・保存形式・データ構造については、AGENTS.mdの一般説明より現在コード・テスト・YAMLを優先する。

---

### Step 3. 課題を定義する

「何を実装できるか」ではなく、

**現在の体験のどこを改善したいのか**

を先に定義する。

例：

- 操作が分かりにくい
- Roomの景観にUIが馴染まない
- Long-term loopが弱い
- 再訪理由が弱い
- CatalogとRoomの責務が重複している
- Web特有の制約がある

課題が不明確な場合は、実装案を増やさず、現在コードと既存ユーザー観察から最も妥当な課題を整理する。

---

### Step 4. 候補案を比較する

原則として2〜5案程度を比較する。

比較項目は必要なものだけ使用する。

代表例：

- ユーザー価値
- 世界観への影響
- 初見理解
- 操作数
- 実装コスト
- テストコスト
- Assetコスト
- Provider追加
- Repository追加
- SharedPreferences変更
- migration
- 既存ユーザー互換
- Web特有リスク
- スマホ操作性
- PC操作性
- accessibility
- 将来拡張性
- 既存設計との整合
- 撤退しやすさ
- MVPとの相性

数値評価や「高・中・低」の比較表を使ってよい。

---

### Step 5. 既存仕様との衝突を確認する

以下を必ず確認する。

- tutorial
- Letter配信
- Weather / Season
- Furniture / Catalog
- Room interaction
- SharedPreferences
- 既存Asset
- 既存ユーザーデータ
- Firebase Hosting / Web制約

関連しない項目は無理に調査しなくてよい。

---

### Step 6. MVPスコープを決める

最小スコープを明示する。

含めるものと、今回やらないものを分ける。

「ついでにできる」ことは理由にならない。

MVPでは、

- 新しい抽象化
- 汎用editor
- 共通system
- 将来用Provider
- 先回りしたmigration
- 不要なAsset追加

を避ける。

---

### Step 7. 1案へ絞る

最終的に、原則1案だけ推奨する。

推奨理由では、

- ユーザー体験
- 既存実装再利用
- 実装リスク
- 保存互換
- MVP

の観点を重視する。

「どれも一長一短」で終わらせない。

---

## Required output

Audit結果は原則として以下の順で整理する。

1. 現在実装
2. 現在仕様
3. 現在の課題
4. 候補案
5. 比較
6. 既存仕様への影響
7. 保存データへの影響
8. tutorialへの影響
9. UI / interactionへの影響
10. 実装コスト
11. テストコスト
12. リスク
13. MVP最小スコープ
14. 推奨案
15. 推奨理由
16. 現在仕様
17. 変更案
18. 変更予定ファイル
19. 新規ファイル候補
20. Provider / Repository / SharedPreferences / YAML / Assetへの影響
21. テスト方針
22. 実ブラウザ確認項目
23. 今回やらないこと
24. 次version以降へ回すもの

内容が小さいAuditでは項目を統合してよい。

---

## Current spec vs proposed change

仕様変更を提案する場合は必ず、

## 現在仕様

と

## 変更案

を分ける。

現在実装と提案仕様を混ぜない。

---

## File planning

推奨案では、実装した場合の変更予定ファイルを示す。

各ファイルについて可能なら以下を示す。

- 既存変更 / 新規
- 推奨配置
- 変更理由

Flutter初心者でも分かる説明を付ける。

---

## Testing policy

実装案に対応する最低限のテストを整理する。

必要に応じて以下を含める。

- Widget test
- Provider test
- Repository test
- 保存・復元
- 旧データ互換
- interaction競合
- keyboard
- Semantics
- 320px
- 390px
- PC幅
- Chrome
- Safari
- reload
- console error
- overflow

---

## Browser validation

UI・animation・audio・Room interactionに関する変更では、Widget testだけで完了判定しない。

実ブラウザで確認すべきポイントを明示する。

ただしAudit段階ではブラウザ操作自体を実施する必要はない。

---

## Do not do during Audit

明示的な依頼がない限り、Audit中は以下を行わない。

- コード変更
- YAML変更
- Asset制作
- SharedPreferences変更
- migration
- package追加
- commit
- tag
- push
- Firebase deploy

---

## Avoid overengineering

以下のような提案は、現在必要な明確な理由がない限り避ける。

- 汎用Event System
- generic editor
- global state追加
- 大規模Repository再編
- unnecessary abstraction
- 将来用の拡張ポイント
- 複数version分の先行実装

---

## Completion criteria

Audit完了とは、

- 現在実装が整理されている
- 課題が明確
- 候補比較がある
- 既存仕様との衝突が確認されている
- MVPスコープが決まっている
- 1案へ絞れている
- 実装予定ファイルとテスト方針が分かる
- 今回やらないことが明示されている

状態を指す。

実装は別タスクで行う。