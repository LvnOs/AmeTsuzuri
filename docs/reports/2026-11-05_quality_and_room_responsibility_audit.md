# 品質レビュー・Room責務分離 統合レポート

- 作成日: 2026-11-05
- 対象リポジトリ: `ame_tsuzuri`
- 調査時HEAD: `ec27c8e` (`Lint対応`)
- 対象範囲: 前回の第三者品質レビュー、および `room_page.dart` の責務分離Audit
- この文書の目的: 企画段階で修正優先順位を判断でき、開発段階では各修正タスクの根拠・対象・完了条件として直接参照できる状態にする

## 1. 結論

現時点で最優先なのは、家具購入時に雫だけが失われ得る状態不整合への対処である。

次に、日次体験を損なう配達失敗からの回復と、配置保存データ破損時の復旧性を改善する。その後、動作をテストで固定したうえで `room_page.dart` のPresentation責務を段階的に分割する。

推奨順序は以下とする。

1. **P0: 家具購入の状態不整合を抑止する**
2. **P1-A: 一時的な配達失敗から同日中に回復できるようにする**
3. **P1-B: 配置保存データ破損時に安全に復旧できるようにする**
4. **P2: `room_page.dart` の描画責務を段階的に分割する**
5. **P3: 雫状態の異種並行更新を直列化する**

P0、P1はユーザー状態または主要体験に直接影響する不具合対応である。P2は保守性改善であり、P0/P1の修正より先に大規模に着手しない。P3は現在UIからの到達可能性が低いため、並行操作を増やす機能の前まで延期可能である。

## 2. 調査の前提と確認状況

### 確認済み

- Flutterアプリで、状態管理は `provider` の `ChangeNotifier`、永続化はRepository経由の `shared_preferences` を使用している。
- 手紙配達、チュートリアル、雫、家具購入・配置、本棚は横断フローになっている。
- `room_page.dart` は2,841行、対応する `room_page_test.dart` は5,813行ある。
- `room_page.dart` は永続化を直接行わず、Provider・Repository・`LetterDeliveryService` を利用している。この層分け自体は維持すべきである。
- 前回レビューで指摘した4件は、調査時HEADでも該当コードが残っている。

### 未検証・残存リスク

- 実端末でSharedPreferences書き込みが失敗した場合の再現
- Android / iOSのリリースビルド
- Chrome / SafariでのRoom分割後の見た目・hit test
- オンライン脆弱性データベースを利用した依存関係監査
- OS強制終了など、2つの永続化処理の途中でプロセスが終了するケース

### 前回レビュー時の検証結果

前回レビューは2026-10-31、当時のHEAD `61576cc` を対象に実施した。

- `C:\Develop\flutter\bin\cache\dart-sdk\bin\dart.exe analyze`: 成功、指摘なし
- `flutter test`: 成功、653テスト通過
- `git diff --check`: 成功
- `flutter analyze`: 60秒以上出力がなく中断。上記 `dart analyze` で静的解析を代替確認

今回の統合レポートはHEAD `ec27c8e` で該当コードが残っていることを再確認したが、コード本体を変更していないため `flutter analyze` と `flutter test` は再実行していない。各修正タスクでは、その時点のHEADで改めて実行する。

### セキュリティ・ドキュメント補足

- 前回レビューでは、秘密情報の直書き、認証認可の欠落に起因する公開機能上の問題、危険な外部通信は確認されなかった。ただしオンライン脆弱性データベースによる依存監査は未実施であり、セキュリティを保証するものではない。
- `README.md` はFlutter初期テンプレートに近く、保存形式、主要フロー、プロトタイプ操作、リセット・復旧方法が記録されていない。今回の不具合修正より優先しないが、公開準備時の保守改善候補とする。

## 3. 優先順位一覧

Critical相当の確認済み問題はない。前回レビューの重要度と、実際の着手順を示す優先度は以下のとおり。

| 優先度 | 重要度 | 指摘 | 種別 | ユーザー影響 | 現在の確認状況 | 推奨対応時期 |
|---|---|---|---|---|---|---|
| P0 | High | 家具購入が非原子的で雫だけ失われ得る | 正確性・保存整合性 | 高。雫消失、所有状態消失、再試行不能 | コード上で確認済み | 次の機能開発・公開前 |
| P1-A | Medium | 配達失敗後に同日中の再試行が封じられる | 正確性・非同期 | 中〜高。1日分の主要体験を失う | コード上で確認済み | P0直後 |
| P1-B | Medium | 配置データ破損時にリセットでも復旧できない | 例外処理・復旧性 | 中。家具機能が利用不能になる | コード上で確認済み | P1-Aと同version候補 |
| P2 | Medium（保守性） | `room_page.dart` が複数のPresentation責務を抱える | 保守性・テスト容易性 | 間接的。変更競合と回帰リスク増加 | 構造・規模を確認済み | P0/P1の後、次のRoom機能前 |
| P3 | Low | 異なる雫操作の並行実行で更新を失い得る | 並行処理・将来リスク | 現UIでは低、拡張後は高くなり得る | コード経路確認済み、現UI再現未検証 | 並行入口追加前 |

## 4. P0: 家具購入の状態不整合

### 指摘内容

`CatalogProvider.buy()` は、先に雫を永続的に消費し、その後に購入家具を別のSharedPreferencesキーへ保存する。

対象:

- `lib/features/furniture/provider/catalog_provider.dart:61-96`
- `lib/features/furniture/repository/purchased_furniture_repository.dart:14-18`
- `lib/features/letters/provider/shizuku_provider.dart:155-173`

現在の順序:

1. `consumeShizuku()` が残高を保存する
2. `_purchasedFurnitureIds` をメモリ上で変更する
3. 購入済み家具一覧を保存する

3で例外が発生すると、雫は減ったまま、メモリ上では購入済み、永続状態では未購入となる。再起動後は家具だけ消失する。

さらに、`PurchasedFurnitureRepository` は `setStringList()` のbool結果を検査していないため、書き込みが `false` を返しても購入成功として扱われる。

### 発生条件・影響範囲

- SharedPreferencesの購入履歴保存が例外になる
- `setStringList()` が `false` を返す
- 2つの保存の間にアプリが終了する

影響:

- 雫だけが失われる
- 同一セッションでは購入済み扱いになり再試行できない場合がある
- 再起動後に購入家具が消える
- チュートリアル中の場合、家具購入・配置・本棚への横断フローが停止する可能性がある

### 修正方針

#### MVP修正

現在のProvider / Repository構成を維持し、以下を実施する。

- `setStringList()` の結果を検査し、失敗時は例外にする
- 購入履歴保存に失敗した場合、メモリ上の購入追加を戻す
- 消費済み雫を補償して戻す
- 補償処理にも失敗した場合は例外を握り潰さず、状態再読込または明示的な復旧経路を用意する

このMVP修正は通常の保存失敗を改善するが、2つの保存の間でOSに強制終了されたケースまで完全には保証しない。

#### 完全な整合性が必要な場合の企画判断

身内テストを超えてユーザー資産として雫を扱う段階では、以下のいずれかが必要になる。

- pending purchaseを保存し、次回起動時に取引を完了または巻き戻す
- 残高と購入履歴を同一の永続状態として保存する

これは保存形式・migrationへ影響するため、今回のMVP修正に自動的に含めない。企画側で「強制終了を含む完全整合性を今回保証するか」を決める。

### 修正対象ファイル

| 種別 | ファイル | 変更内容 |
|---|---|---|
| 既存変更 | `lib/features/furniture/provider/catalog_provider.dart` | 失敗時のメモリ復元、雫補償、結果制御 |
| 既存変更 | `lib/features/furniture/repository/purchased_furniture_repository.dart` | SharedPreferencesのbool結果検査 |
| 既存変更候補 | `lib/features/letters/provider/shizuku_provider.dart` | 補償処理に既存 `addShizuku()` を使えるかを確認し、必要最小限だけ調整 |
| 既存変更 | `test/features/furniture/provider/catalog_provider_test.dart` | 購入成功・各失敗段階・再試行テスト追加 |
| 新規候補 | `test/features/furniture/repository/purchased_furniture_repository_test.dart` | 保存結果false、保存・読込のRepositoryテスト |
| 既存変更候補 | `test/features/furniture/presentation/catalog_page_test.dart` | 失敗時メッセージと残高・購入表示の整合確認 |

### 完了条件

- 購入履歴保存失敗後に雫残高と所有状態が矛盾しない
- 失敗後に同じ家具を再試行できる
- Provider再生成後も期待状態が復元される
- 同じ購入操作が二重実行されない
- チュートリアルの初回購入・配置フローが通る

## 5. P1-A: 配達失敗後の同日回復

### 指摘内容

`_scheduleDelivery()` は配達開始前に `_attemptedDeliveryDate` を設定するが、手紙読込または配達保存に失敗しても解除しない。

対象:

- `lib/features/room/presentation/room_page.dart:826-915`
- `test/features/room/presentation/room_page_test.dart` の「今日の手紙の配達表示」「通常手紙の翌日配達と天候再試行」

catchコメントには後のRoom rebuildで再試行するとあるが、同じ日付は `_scheduleDelivery()` 冒頭で拒否される。

### 発生条件・影響範囲

- `LetterRepository.getAll()` が一時的に失敗する
- `ReadLetterProvider.deliver()` の保存が一時的に失敗する

影響:

- 同日中はrebuildしても配達されない
- 日付を進めるまで回復しない
- チュートリアル初回配達でも発生し得る

天候ロードについては既存テストで2回までの再試行上限が明示されているため、今回の修正では無制限再試行へ変更しない。

### 修正方針

- 例外または保存失敗の場合だけ `_attemptedDeliveryDate` を解除する
- 「候補なし」「天候不一致」「既に配達済み」では解除しない
- rebuildごとの無限ロードを避ける
- 必要であれば1回の明示的な再試行スケジュールを設けるが、既存の天候再試行とは重複させない

### 修正対象ファイル

| 種別 | ファイル | 変更内容 |
|---|---|---|
| 既存変更 | `lib/features/room/presentation/room_page.dart` | 配達試行状態の成功・失敗別管理 |
| 既存変更 | `test/features/room/presentation/room_page_test.dart` | Repository失敗・保存失敗後の同日回復テスト |

### 完了条件

- 最初の読込または保存を1回失敗させ、同日中の次回機会に1通だけ配達される
- 成功後のrebuildで2通目が配達されない
- 候補なしの場合に毎rebuildでRepositoryを読み続けない
- 日付変更中の古い日付へ配達されない

## 6. P1-B: 配置保存データ破損時の復旧

### 指摘内容

配置データのJSON解析とvalueキャストに防御がなく、破損データを読むとProviderのloadが失敗する。またPrototype resetは全Providerを先にloadするため、破損状態をclearする前に停止する。

対象:

- `lib/features/furniture/repository/placed_furniture_repository.dart:8-25`
- `lib/features/room/presentation/prototype_reset_page.dart:41-90`
- `lib/features/furniture/provider/placed_furniture_provider.dart`

### 発生条件・影響範囲

- 不正JSON
- JSON valueがString以外
- 将来の保存形式変更または途中書き込み

影響:

- `PlacedFurnitureProvider.isLoaded` がtrueにならない
- Room・Catalogの家具操作が利用不能になる
- 「最初からやり直す」でも復旧できない

### 修正方針

- JSON解析例外を処理する
- key/valueの型を1件ずつ検証する
- 不正エントリを除外するか、状態全体を空として扱うかをテストで固定する
- resetは既存状態のload成功を前提にせず、Repositoryを直接初期化できる経路にする
- 新しい保存形式やmigrationは追加しない

### 修正対象ファイル

| 種別 | ファイル | 変更内容 |
|---|---|---|
| 既存変更 | `lib/features/furniture/repository/placed_furniture_repository.dart` | 防御的decode、保存・clear結果検査 |
| 既存変更 | `lib/features/room/presentation/prototype_reset_page.dart` | load失敗状態からもreset可能にする |
| 既存変更候補 | `lib/features/furniture/provider/placed_furniture_provider.dart` | Repository方針に合わせたloadエラーの扱い |
| 新規候補 | `test/features/furniture/repository/placed_furniture_repository_test.dart` | 不正JSON・型不正・正常復元テスト |
| 既存変更 | `test/features/room/presentation/room_page_test.dart` またはPrototype reset用テスト | 破損状態からのリセット復旧 |

### 完了条件

- 不正JSONでアプリがクラッシュしない
- 非String valueを安全に扱う
- リセット操作で正常な空状態へ戻せる
- 正常な旧配置データは維持される

## 7. P2: `room_page.dart` の責務分離

### 現在仕様

アーキテクチャ上は以下が分離されている。

- 永続化: Repository
- 共有状態: Provider
- 通常手紙の選択: `LetterDeliveryService`
- 季節演出等の一部Widget: `presentation/widgets/`

この分離は適切であり、維持する。

一方、`room_page.dart` 内には次の異なる変更理由が集まっている。

- Provider状態の集約
- 配達・開封・画面遷移
- チュートリアル進行
- Weatherロード
- 模様替え操作
- プロトタイプ操作
- Room Stackとhit test
- 家具別描画
- 到着・チュートリアル演出
- 約120件の配置・演出設定

構造上の指標:

- `room_page.dart`: 2,841行
- `room_page_test.dart`: 5,813行
- 同一ファイル内private class: 17
- `_RoomBackgroundLayers` のrequired引数: 45

### 変更案

新しいProvider、Repository、保存状態は追加せず、純粋なPresentation責務だけを段階的に別ファイルへ移す。

推奨する最初の分割:

1. 模様替えOverlay
2. 家具描画Layer
3. Room Sceneと演出

`_RoomPageState` には以下を残す。

- Provider状態の集約
- 配達・開封・画面遷移
- AnimationControllerの所有とdispose
- 模様替え結果のProvider反映
- チュートリアル進行の調整

### 候補比較

| 案 | 内容 | コスト | リスク | 判定 |
|---|---|---|---|---|
| 現状維持 | private Widgetの論理分割のみ | 低 | 変更競合と巨大テストが継続 | 非推奨 |
| Presentationだけ分割 | 状態遷移を維持し、描画Widgetを別ファイル化 | 中 | 挙動変更を混ぜなければ低〜中 | 推奨 |
| Room専用Controller / Provider追加 | Page状態を外部へ移動 | 高 | 既存Providerとの責務重複、過剰設計 | 今回は行わない |

### 修正・新規ファイル候補

| 種別 | ファイル | 責務 |
|---|---|---|
| 既存変更 | `lib/features/room/presentation/room_page.dart` | 状態集約と画面フローに限定する |
| 新規 | `lib/features/room/presentation/widgets/room_rearrange_overlay.dart` | 模様替えタグ、slot marker、geometry、picker起点の表示 |
| 新規 | `lib/features/room/presentation/widgets/room_furniture_layers.dart` | 花、椅子、カーテン、ラグ、汎用家具画像、リアクションtap area |
| 新規候補 | `lib/features/room/presentation/widgets/room_scene.dart` | Room Stack、背景、固定オブジェクト、主要tap area |
| 新規候補 | `lib/features/room/presentation/widgets/room_tutorial_effects.dart` | Glow、moving light、Room内tutorial表示。Scene分割後も大きい場合のみ |
| 既存変更 | `test/features/room/presentation/room_page_test.dart` | 全体フロー・Provider連携・画面遷移だけを残す |
| 新規 | `test/features/room/presentation/widgets/room_rearrange_overlay_test.dart` | marker、Semantics、keyboard、hit test、各幅 |
| 新規 | `test/features/room/presentation/widgets/room_furniture_layers_test.dart` | 家具描画、欠損asset、fallback、reaction |

### 実装上の注意

- ファイル分割とUI変更を同じ差分にしない
- 座標、duration、opacity、key、Semantics文言を変更しない
- 45引数を解消する目的だけで巨大な設定クラスを作らない
- Dart `part` による見かけ上の分割だけで終わらせず、各Widgetの入力責務を明確にする
- test-only getterを増やすより、分離後のWidgetを直接テストする

### 完了条件

- Provider / Repository / SharedPreferences / YAML / Assetに変更がない
- tutorial、配達、模様替え、家具表示の既存テストが通る
- 320px、390px、PC幅でoverflowとtap area競合がない
- keyboardとSemanticsが維持される
- 実ブラウザで到着演出、Glow、模様替え、家具リアクションを確認する

## 8. P3: 雫状態の異種並行更新

### 指摘内容

`ShizukuProvider` は同じLetter IDへの並行報酬だけを共有する。異なるLetter ID、報酬と消費、報酬とprototype加算などは、同じ旧状態から次状態を作れる。

対象:

- `lib/features/letters/provider/shizuku_provider.dart:103-173`
- `test/features/letters/provider/shizuku_provider_test.dart` の並行報酬テスト

現在UIでは手紙連打と家具購入の多重実行が抑止されているため、通常操作からの再現可能性は低い。ただし公開メソッドを別のUIから同時利用すると、最後に完了した保存が他方の残高または報酬済みIDを上書きし得る。

### 修正方針

- 雫状態を変更する処理をProvider内の単一キューで直列化する
- 新しいProviderやpackageは追加しない
- 同一Letter IDの既存Future共有仕様は維持する
- P0の補償処理と競合しないことを確認する

### 修正対象ファイル

| 種別 | ファイル | 変更内容 |
|---|---|---|
| 既存変更 | `lib/features/letters/provider/shizuku_provider.dart` | 全更新の直列化 |
| 既存変更 | `test/features/letters/provider/shizuku_provider_test.dart` | 異なる報酬、報酬と消費の並行テスト |

### 着手条件

以下のいずれかに該当するまで延期可能。

- Room以外からLetter報酬を受け取る
- バックグラウンド処理で雫を変更する
- 購入以外の消費導線を追加する
- P0の補償処理により並行更新経路が増える

## 9. 推奨着手順

### Step 0: ベースライン固定

1. 作業開始時の `git status` を確認する
2. 対象個別テストを実行する
3. 指摘の再現テストを先に追加し、現状で失敗することを確認する

目的は、修正と既存不具合を区別できるようにすることである。

### Step 1: P0 家具購入

1. `CatalogProvider` の失敗段階をテストで再現
2. Repositoryのbool結果検査を追加
3. メモリ状態の復元と雫補償を実装
4. チュートリアル購入・配置のWidgetテストを確認
5. 全テストを実行

### Step 2: P1-A 配達回復

1. 手紙読込失敗後の同日再試行テストを追加
2. 配達保存失敗後の同日再試行テストを追加
3. 成功後の二重配達防止を確認
4. 天候2回上限の既存仕様を維持

### Step 3: P1-B 破損復旧

1. Repository単体の破損データテストを追加
2. 防御的decodeを実装
3. load失敗に依存しないresetを実装
4. 正常な既存配置の互換性を確認

### Step 4: P2 Room責務分離

1. 模様替えWidgetを機械的に移動し、挙動を変えない
2. 模様替え関連テストを分離
3. 家具描画Widgetを移動
4. 家具描画テストを分離
5. 必要なら最後にRoom Sceneを分割
6. Widgetテスト、全テスト、実ブラウザ確認

### Step 5: P3 雫更新直列化

P0で必要性が増した場合、または新しい並行入口を作る直前に実施する。

## 10. 企画判断用チェックポイント

企画用プロンプトでは、単に優先順位を追認せず、以下を開発担当と確認する。

### P0を今回必須にする判断

- 次のversionで家具購入をテスターに触ってもらうか
- 雫消失をプロトタイプ上の許容事項として扱えるか
- OS強制終了まで保証するか、通常の保存失敗補償まででよいか

推奨判断: 家具購入を公開するならMVP修正は必須。完全トランザクション保証は次段階でもよい。

### P1を今回必須にする判断

- 「1日1通」の日次体験で、当日中に回復不能な失敗を許容できるか
- 保存データ破損時にアプリ再インストール以外の復旧手段が必要か

推奨判断: P1-Aは必須。P1-Bも小さな変更で復旧性が大きく上がるため、同versionで対応する。

### P2を今回実施する判断

- 次versionでRoom、家具、チュートリアルのいずれかを大きく変更するか
- P0/P1の修正が完了し、回帰テストが安定しているか

推奨判断: 次のRoom機能開発前に実施する。P0/P1より先には行わない。

### P3を今回実施する判断

- 雫を変更する新しい非同期導線が増えるか

推奨判断: 増えないなら延期可能。ただしP0補償実装の設計次第で同時対応を再評価する。

## 11. 開発タスク共通ルール

各優先項目は別タスク・別差分として扱う。

- 現在実装とテストを仕様の正とする
- 無関係なrefactorを行わない
- 新しいProvider、Repository、package、保存形式を安易に追加しない
- 永続形式を変更する場合はversion管理と旧データ互換を別途設計する
- UI変更を不具合修正またはファイル分割へ混ぜない
- 同じLetter報酬の重複防止、1日最大1通、瓶進捗と残高の分離を維持する
- チュートリアル横断フローを関連テストで確認する

## 12. テスト方針

### 各タスク共通

1. 変更範囲の個別テスト
2. `flutter analyze`
3. `flutter test`
4. `git diff --check`

### P0

- Provider単体: 各保存段階の失敗、補償成功・失敗、再試行
- Repository単体: bool結果false
- Widget: 残高表示、購入表示、エラー表示、チュートリアル導線

### P1-A

- Widget: Repository失敗後の再試行、保存失敗後の再試行
- 日付変更競合
- 成功後の二重配達防止

### P1-B

- Repository: 不正JSON、型不正、空値、正常値
- Reset: Provider load失敗状態からの復旧
- 旧配置の復元

### P2

- 既存Widgetテストを維持
- 320px、390px、PC幅
- tap area重複
- keyboard、Semantics
- animation dispose / ticker leak
- Chromeでreload、console error、overflow

### P3

- 異なるLetter IDへの並行報酬
- 報酬と消費の並行実行
- 保存失敗後にキューが停止しないこと

## 13. 実ブラウザ確認項目

P2を実施した場合、Widgetテストだけで完了としない。

- 新規配達のポスト発光から手紙表示まで
- チュートリアルのLetter → 瓶 → 本棚Glow
- 模様替え開始・slot選択・保存・終了
- 家具の配置、取り外し、fallback表示
- 320px相当の狭幅、390px、PC幅
- マウス、keyboard focus、Enter操作
- 透明tap areaの誤反応
- reload後の配置復元
- console error、overflow、Ticker例外がないこと

## 14. 今回やらないこと

- 汎用Event System
- Room専用の新Provider / Repository
- 汎用Scene Engine
- 家具YAML全体の再設計
- Asset命名規則変更
- UI全体の再デザイン
- P2と同時の座標・演出時間・文言変更
- P0のMVP修正に便乗した永続形式の全面統合

## 15. 企画用プロンプト例

以下を企画検討用チャットへ渡す。

```text
`docs/reports/2026-11-05_quality_and_room_responsibility_audit.md` を参照し、現在実装・テストを正として、次versionで対応する修正範囲をAuditしてください。

特に以下を開発観点と合わせて判断してください。
- P0の家具購入は、通常の保存失敗補償までを今回行うか、OS強制終了を含む完全な取引整合性まで必要か
- P1-AとP1-Bを同じversionへ含めるか
- 次versionでRoom変更予定があるためP2を今回行うべきか
- P0の実装によりP3の並行更新対策を前倒しすべきか

各項目について、ユーザー影響、実装コスト、テストコスト、保存互換、チュートリアル影響、延期リスクを比較し、今回実施する1つのスコープへ絞ってください。
コードは変更せず、現在仕様と変更案を分けて報告してください。
```

## 16. 開発用プロンプト例

一度に全項目を依頼せず、下記の `<対象>` を1項目だけ指定する。

```text
`docs/reports/2026-11-05_quality_and_room_responsibility_audit.md` を参照し、<対象: P0 / P1-A / P1-B / P2 / P3> を実装してください。

要件:
- レポート記載の現在仕様、修正方針、対象ファイル、完了条件を基準にする
- 着手前に現在コードと該当テストを再確認し、レポートとの差異があれば現在実装を正として報告する
- 変更範囲に対応する再現テストまたは回帰テストを先に追加する
- 無関係なrefactor、UI変更、YAML・Asset変更、package追加を行わない
- 新しいProvider、Repository、保存形式は、レポートの対象項目で明示されない限り追加しない
- チュートリアル、1日最大1通、報酬重複防止、瓶進捗と残高の分離を維持する
- 個別テスト後に `flutter analyze`、`flutter test`、`git diff --check` を実行する

完了報告には、変更ファイル、変更内容、レポートの完了条件との対応、実行した検証コマンド、残存リスクを記載してください。
```

## 17. 完了判定

このレポートに対する修正プロジェクト全体の完了条件は以下。

- P0で通常の保存失敗時に雫と所有状態が矛盾しない
- P1-Aで一時失敗後に同日中の配達が回復する
- P1-Bで配置データ破損からアプリ内操作で復旧できる
- P2実施時にRoomの既存挙動を変えず、Presentation責務とテストが分割される
- P3実施時に異種並行更新で残高・報酬IDを失わない
- 全項目で既存ユーザーデータとチュートリアル横断フローへの影響が確認される

品質が完全に保証されたことを意味するものではない。実端末、リリースビルド、ブラウザ、強制終了条件は、それぞれ該当versionの公開判断時に追加確認する。
