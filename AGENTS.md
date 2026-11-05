# Repository instructions

- ユーザーへの報告は、指定がなければ日本語で行う。
- 既存の無関係な変更を保持し、依頼範囲外の機能・データ・リファクタリングを行わない。
- 既存の実装パターンを優先し、プロトタイプ段階では過剰設計や不要な依存追加を避ける。
- 完了報告には、変更ファイル、主な変更内容、実際に実行した検証コマンドを記載する。
- タスク固有の詳細手順は、該当するSkillがある場合はSkillを使用する。作業開始時にすべてのSkillを読み込まず、現在の依頼に必要なものだけ使用する。

## Task-specific skills

Repository固有の反復作業は `.agents/skills/` 以下のSkillに定義する。

現在利用するSkillは以下。

### `$feature-audit`

パス：

```text
.agents/skills/feature-audit/SKILL.md
```

以下の場合に使用する。

- 新機能を実装する前の調査
- 次versionのテーマ検討
- UIや仕様の複数案比較
- 既存仕様を変更するかの判断
- 実装前の影響範囲確認
- ユーザーからAuditを依頼された場合

このSkillを使用するAuditでは、明示的な依頼がない限りコード・Asset・YAML・保存データを変更しない。

### `$letter-content-change`

パス：

```text
.agents/skills/letter-content-change/SKILL.md
```

以下の場合に使用する。

- Letter追加
- Letter本文修正
- `letters.yaml` 更新
- Letterのseason / weather / priority変更
- tutorial Letter本文変更
- Letter追加に伴うテスト更新

Letter配達ロジック、Bookshelf UI、Letter到着演出などの機能実装そのものは、このSkillだけで処理せず通常の実装タスクまたは `$feature-audit` として扱う。

### `$release-deploy`

パス：

```text
.agents/skills/release-deploy/SKILL.md
```

以下の場合に使用する。

- release
- commitを含む公開準備
- tag作成
- push
- Firebase Hosting deploy
- 身内テスト用Web版の更新

release / deployでは、このSkillに定義されたRepository確認、検証、Firebase project確認、公開後確認を省略しない。

## Product principles

「雨つづり。」は、雨の日を少し楽しみにするための、静かな世界観を重視したアプリである。

- 世界観を壊す一般的なアプリUIを安易に追加しない。
- ただし、雰囲気のために操作性や理解しやすさを犠牲にしている場合は、その問題を明示する。
- UI変更では「世界観」と「初見でも操作を理解できること」の両立を重視する。
- 大規模な機能追加より、仮説を検証できる小さな変更を優先する。

## Architecture

Flutterアプリで、状態管理は `provider` の `ChangeNotifier`、永続化はRepository経由の `shared_preferences`、コンテンツ定義は `assets/data/*.yaml` と `assets/letters/*.md` を使用する。

永続状態の形式を変更するときは、既存のバージョン管理・旧キーからの移行処理との互換性を維持する。

現在の設計で解決できる場合は、新しいProvider、Repository、永続状態、packageを追加しない。

## Product invariants

- 1日につき配達される手紙は最大1通。
- 初回はチュートリアル用の手紙を優先する。
- 通常手紙は未読状態、季節、天気、YAML上の優先順位によって選択される。
- 手紙報酬は同じ手紙について重複して獲得できない。
- 瓶の進捗と現在の雫残高は別の概念として扱う。
- チュートリアルは手紙、雫、家具購入・配置、本棚にまたがる横断フローであるため、関連機能を変更するときはフロー全体への影響を確認する。
- 家具マスターには将来用の非公開家具が意図的に含まれるため、未使用やアセット不足だけを理由に削除しない。
- YAMLやアセットを変更するときは、関連するMarkdown、画像パス、配置スロットID、`pubspec.yaml` のアセット登録との整合を確認する。

具体的な配信条件、報酬値、保存形式、データスキーマなどは、AGENTS.mdやSkillの一般的な記述より現在の実装・テスト・`assets/data/*.yaml`を正とする。

Skillの記述と現在実装が食い違う場合は、現在実装を確認したうえで差異を報告し、古いSkillの記述を事実として扱わない。

## Scope control

依頼された目的を達成するために必要な最小変更を優先する。

特に明示的な理由がない限り、以下を「ついで」に行わない。

- 無関係なrefactor
- 将来用の抽象化
- 汎用system化
- package追加
- 保存形式変更
- migration追加
- UI全体の再設計
- YAML全体の並び替え
- Asset命名規則の一括変更

現在の設計に改善余地があっても、今回の依頼範囲外であれば、必要に応じて別途候補として報告するだけに留める。

## Validation

変更範囲に対応するテストを先に実行し、完了前には原則として以下を実行する。

```powershell
flutter analyze
flutter test
```

UI・アニメーション・非同期処理を変更した場合は、関連するWidgetテストへの影響も確認する。

変更内容に対応する個別テストがある場合は、全テストより先に実行する。

release / tag / push / Firebase Hosting deployを含む作業では `$release-deploy` を使用し、そこで定義された追加検証を行う。

Windowsローカル開発環境では通常Flutter SDKとして `C:\Develop\flutter` を使用する。

このパスが存在しない環境では、存在を仮定して設定や環境を変更せず、現在利用可能なFlutter環境を確認する。

CLI検証ではワークスペース外のSDKキャッシュへの書き込み権限が必要になる場合がある。

Flutter/Dartプロセス競合時は、用途を確認せずに関連プロセスを一括終了しない。

## Source of truth

仕様確認では、情報の種類に応じて以下を優先する。

現在の動作・保存形式・データ構造：

```text
実装
→ テスト
→ YAML / Markdown
→ AGENTS.md / Skill
```

開発方針・作業ルール：

```text
AGENTS.md
→ 該当Skill
→ 既存実装パターン
```

過去のAudit結果や古いプロンプトだけを根拠に現在仕様を決めない。

不明な点がある場合は、必要なコード・テスト・データだけを確認し、Repository全体を無目的に読み込まない。

## Unexpected blockers

作業中に想定外の停止・長時間の待機・同じ失敗の反復が発生した場合、原因不明のまま同じ操作を繰り返さない。

以下の場合は、作業を続ける前に状況を整理して報告する。

- コマンドやプロセスが通常より明らかに長時間完了しない
- 同じ操作・テスト・ブラウザ操作が繰り返し失敗する
- 環境・権限・外部ツールの問題により、本来の作業を進められない
- 追加調査が必要で、当初の依頼範囲を大きく超えそうな場合

ユーザーからの明示的な承認を待っている時間は、想定外の停止には含めない。

報告する場合は以下の形式を使用する。

### 想定外の停止事項

- 発生内容：
- 影響：
- 暫定対応：
- 別途調査が必要な事項：