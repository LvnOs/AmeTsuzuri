---
name: flutter-test-scope
description: 「雨つづり。」のFlutter/Dartコードを変更・レビュー・テストするときに、差分と回帰リスクから直接テスト、影響範囲テスト、全件テスト、静的解析、Webビルドを選定する。
---

# flutter-test-scope

## 選定手順

検証前に、今回の差分と現在の実装・テストを確認する。

- **A. 変更ファイル** — 基準コミットとの差分と作業ツリーを確認し、今回の実装・テスト・設定・Assetの変更を把握する。
- **B. 変更した振る舞い** — 追加・変更した動作と維持すべき仕様を特定する。
- **C. 直接テスト** — 変更したクラス・メソッド・Widgetを検証する既存テストを、参照箇所や期待値から探す。
- **D. 波及範囲** — 呼び出し元、共通Provider、Repository、保存データ、画面遷移やチュートリアルなどの横断フローをたどる。
- **E. 回帰リスク** — 旧データとの互換性、非同期の完了順・画面離脱・連打、読込や保存の失敗と再試行など、該当する境界を確認する。
- **F. 静的解析とビルド** — 変更内容に必要なanalyzeの範囲とWebビルドの要否を決める。

実行前に選定範囲と理由を簡潔に示す。失敗時は実装・テスト・環境のどこに原因があるかを調べ、必要に応じて範囲を広げる。変更ファイル数ではなく変更の性質と波及範囲で判断し、重大な回帰を検出できる範囲を選ぶ。

## テストの段階

- **Level 1 — 直接テスト**。実装途中は、変更した実装を直接検証するテストを優先する。差分に含まれない既存テストも対象にする。UI・アニメーション・非同期処理では関連するWidgetテストを確認する。
- **Level 2 — 影響範囲テスト**。実装完了時やPR前に、Level 1に加えて呼び出し元や関連機能の回帰を検証する。広い場合は、旧データ読込、二重保存、画面遷移中の状態変化など、変更に関連する重大な境界条件を優先する。
- **Level 3 — 全件テスト**。毎回の必須条件にはせず、次の場合に原則実行する。
  - リリース前、または全件テストを明示的に依頼された場合
  - 共有基盤や複数機能にまたがる大きな変更、大規模リファクタリング
  - 保存形式・永続化処理の広範な変更
  - 依存関係・Flutter SDK・テスト基盤の変更
  - 影響範囲を合理的に限定できない場合

開発手順などのドキュメントだけを変更した場合は、参照先や記述内容、`git diff --check` を確認する。Letterコンテンツを変更する場合は `letter-content-change` の検証も適用する。リリース時は `release-deploy` の検証（全件テスト、ルートのanalyze、Webビルドなど）を優先する。

## 静的解析とWebビルド

- Dart/Flutterコード変更では、影響範囲に応じてanalyzeを実行する。PR前は原則として `flutter analyze --no-pub lib test` を実行する。
- Web固有処理、Assetの登録・読込、アプリ起動、音声、JavaScript連携、デプロイに関わる変更ではWebビルドを選定する。小さな純粋Dartロジック変更では、Webへの波及がなければ省略できる。Widgetテスト、analyze、Webビルドはそれぞれ独立した検証として判断する。
- `tool/audio_loop_smoke` は独自の `.fvmrc`・`pubspec.yaml`・lockfileを持つ独立パッケージ。ルートの `flutter analyze` が音声ツール配下の依存解決エラーを出した場合は、両パッケージのSDKと依存取得状態を確認する。必要に応じて同等の環境で基準コミットの診断と比較し、既知の環境起因エラーと本体の新規診断を切り分ける。アプリ限定の解析が成功しても、ルート解析のエラーは原因と結果を報告する。音声ツール自体の変更は、そのパッケージのSDKで検証する。

## 環境別コマンド

実行前に使用するSDK・コマンドと対象パスが存在することを確認する。`--no-pub` は対象パッケージの依存取得が済んでいる場合に使う。準備が必要ならREADMEと各パッケージの `.fvmrc` を確認する。Codex Cloudでは `bash tool/cloud/setup.sh` で両パッケージを準備し、音声ツールは `bash tool/cloud/run.sh --audio flutter analyze --no-pub` のように実行する。Macは対象パッケージのディレクトリでFVMを使う。WindowsはREADMEに従って実在する本体用SDKをPowerShellで選び、`Get-Command flutter -All` と `flutter --version` で確認する。音声ツールの依存取得には音声ツール用SDKを使う。

以下はリポジトリ直下で本体を検証する例。分析やビルド、全件テストは選定した場合に実行する。

| 操作 | Codex Cloud | Mac | Windows |
| --- | --- | --- | --- |
| テストファイル | `bash tool/cloud/run.sh flutter test --no-pub test/features/room/presentation/room_page_test.dart` | `fvm flutter test --no-pub test/features/room/presentation/room_page_test.dart` | `flutter test --no-pub test/features/room/presentation/room_page_test.dart` |
| テストディレクトリ | `bash tool/cloud/run.sh flutter test --no-pub test/features/letters` | `fvm flutter test --no-pub test/features/letters` | `flutter test --no-pub test/features/letters` |
| 全件テスト | `bash tool/cloud/run.sh flutter test --no-pub` | `fvm flutter test --no-pub` | `flutter test --no-pub` |
| 本体の静的解析 | `bash tool/cloud/run.sh flutter analyze --no-pub lib test` | `fvm flutter analyze --no-pub lib test` | `flutter analyze --no-pub lib test` |
| Webビルド | `bash tool/cloud/run.sh flutter build web --no-pub` | `fvm flutter build web --no-pub` | `flutter build web --no-pub` |

## 選定例 — RoomのLetter本文遅延読込

変更ファイルは `room_page.dart`、`letter_delivery_service.dart` と、下記のRoom・配達Service・Letter Repository・Prototype操作の4テスト。配達候補を `LetterSummary` から選び、開封時に該当する本文だけを取得する変更を例とする。

- **Level 1** — `room_page_test.dart` で配達時に本文を取得しないこと、開封時の対象ID、取得中の配達ID変更、連打、取得失敗後の再試行を確認する。`letter_delivery_service_test.dart` と `letter_repository_test.dart` で候補の優先順位・除外条件と、実データを使った候補選択・本文取得を確認する。
- **Level 2** — `prototype_controls_test.dart` と `ame_tsuzuri_app_test.dart` で日付変更・リセットと初回起動時の配達を確認する。`bookshelf_page_test.dart` と `letter_page_test.dart` で共有する本文取得・表示経路を確認する。既読や報酬の保存タイミングへの影響が見つかれば `read_letter_provider_test.dart` と `shizuku_provider_test.dart` に広げる。
- **静的解析・Webビルド** — `lib test` を解析し、起動後のRoomでのAsset読込が変わるためWebビルドを選ぶ。実際のブラウザでの初回配達・開封は、必要に応じて別に確認する。
- **Level 3** — 保存形式や共有の読込API自体に変更がなく、波及を上記の経路に限定できるなら、通常の実装時は全件テストを省略できる。

## 完了報告

- 実行したコマンド、選定したテスト範囲と理由、各コマンドの成功・失敗を記載する。
- 実施したanalyzeとビルド、実施しなかった検証と理由、未確認の挙動や残るリスクを明示する。
- 全件テストの要否と判断理由を記載し、未実行ならその旨を明示する。過去の結果や机上確認は今回の実行結果と区別する。
