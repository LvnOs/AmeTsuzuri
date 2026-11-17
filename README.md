# 雨つづり。

Flutter Webを優先して開発するアプリです。作業方針は[AGENTS.md](AGENTS.md)、音声仕様は[ADR-002](docs/adr/adr-002.md)を参照してください。

## SDKの共通基準

| 対象 | Flutter / Dart | Flutterコミット |
| --- | --- | --- |
| 本体 | 3.47.0 / 3.13.0 | `4cf24164269a5ebf0c16a028a00727d0e77bbb05` |
| `tool/audio_loop_smoke` | 3.44.9 / 3.12.2 | `6b182d2c7585eba26d4edce0f97630effd256c33` |

各ディレクトリの`.fvmrc`はバージョンの宣言です。FVMの導入は必須ではありません。本体と音声検証ツールのlockfileは異なるSDK世代に対応するため、別々のSDKで依存取得します。SDK更新は両lockfileとの互換性を検証する別作業とし、通常の環境準備で`pub upgrade`やlockfile更新を行わないでください。

## Windows（FVMなし）

Git、指定バージョンのFlutter SDK、ChromeまたはEdgeを用意します。既存SDKの所在を先に確認し、`C:\Develop\flutter`の存在を仮定したり、既存SDKを上書きしたりしないでください。SDKはリポジトリ外へバージョン別に配置します。

PowerShellで使用するSDKを選択し、バージョンとコミットを確認します（パスは実際の配置先に置き換えます）。

```powershell
$flutterSdk = 'C:\Develop\flutter-3.47.0'
$env:Path = "$flutterSdk\bin;$env:Path"
Get-Command flutter -All
flutter --version
git -C $flutterSdk rev-parse HEAD
flutter doctor -v
```

VS CodeではFlutter拡張機能の「Flutter: Change SDK」またはユーザー設定で同じSDKを選択します。共有ワークスペース設定はSDKパスを強制しません。既存FVMを使い続ける場合も、CLIとエディターのSDKが一致することを確認してください。

リポジトリ直下から、音声検証ツールの依存を先に取得し、本体を検証します。

```powershell
Push-Location tool/audio_loop_smoke
try {
    & 'C:\Develop\flutter-3.44.9\bin\flutter.bat' pub get --enforce-lockfile
    if ($LASTEXITCODE -ne 0) { throw 'Audio dependency setup failed' }
} finally { Pop-Location }
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub
flutter build web --no-pub --no-web-resources-cdn
flutter run -d chrome --no-pub
```

各コマンドの失敗時は原因を確認してから続行してください。雨音の明示操作による開始、再読み込み後の再開、タブ復帰、ループ境界の聴感はWindowsブラウザでも確認します。

## Codex Cloud / Linux

必要なコマンドはBash、Git、Python 3、curl、unzip、xz、tar、flockです。ブラウザ確認にはChromium、HTTP配信にはPython 3を使用します。FVM、Android SDK、Linuxデスクトップ向けビルドツールの追加は不要です。

既存のチェックアウトを使用してください。クラウドタスクは隔離されているため、依頼がなければ追加のGit worktreeを作りません。

```bash
bash tool/cloud/setup.sh
bash tool/cloud/run.sh flutter analyze --no-pub
bash tool/cloud/run.sh flutter test --no-pub
bash tool/cloud/run.sh flutter build web --no-pub --no-web-resources-cdn
```

スクリプトは自身の位置からリポジトリを特定するため、別のカレントディレクトリから絶対パスで呼び出すこともできます。`run.sh`は本体ディレクトリへ移動し、指定SDKでFlutterを実行します。音声検証ツールを操作する場合は以下を使用します。

```bash
bash tool/cloud/run.sh --audio flutter pub get --enforce-lockfile
```

`setup.sh`は両SDKを取得してコミットを照合し、両パッケージの依存をlockfile厳守で取得します。再実行時はSDKを再利用します。不一致・変更済み・不完全な既存SDKは上書きせず停止します。その場合は表示された場所を調査し、ローカル変更を保護してから対処してください。同時setupはロックで拒否します。検証や開発コマンドの実行中にsetupを並行実行しないでください。

SDK・Pubキャッシュ・Flutter設定・解析状態は、Git無視対象の`.fvm/cloud/`に保存します。ホームディレクトリへの書き込みや`/workspace/flutter-env.sh`には依存しません。`run.sh`はプロセス内でPATHと保存先を設定し、Chromiumがあれば検出します。別ブラウザを使う場合は`CHROME_EXECUTABLE`を指定します。SDKはタグではなく期待コミットまで照合するため、detached HEADのchannel警告は想定内です。

配信確認はリポジトリ直下で行います。

```bash
python3 -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

内部ブラウザまたはHTTPリクエストで、画面起動、YAML・画像の取得、`assets/assets/audio/rain_room_loop.mp3`の取得・デコードを確認します。PIDや開いたポートだけを成功条件にしません。クラウドのlocalhostを外部公開URLとして扱わないでください。配信プロセスは必要な都度起動し、終了後に停止します。

ネットワークでは`github.com`、`pub.dev`、`storage.googleapis.com`と、取得時に必要になる正規のリダイレクト先を許可します。TLSやパッケージ検証は無効化しません。`--no-web-resources-cdn`はCanvasKit等を同梱して描画エンジンの外部CDN依存を避けるための指定です。通常ビルドの確認には`flutter build web --no-pub`も実行できます。

## 新規環境・再実行の検証

1. 同じGitコミットを持つ新しいクラウド環境を用意し、`.fvm/cloud/`と外部の環境初期化ファイルがないことを確認する。作業中のキャッシュを削除して代用しない。
2. `bash tool/cloud/setup.sh`を実行し、SDKコミットと両パッケージの依存取得成功を確認する。
3. 同じsetupを再実行し、既存SDKを保持して成功することを確認する。
4. 上記の解析・テスト・Webビルドと、ブラウザでの配信確認を実行する。
5. `git status --short`、`git diff --check`、`git diff -- pubspec.lock tool/audio_loop_smoke/pubspec.lock`で意図しない変更がないことを確認する。

SDK・キャッシュ・プロセスの永続性は保証しません。キャッシュがあっても各チェックアウトでsetupを実行し、絶対パスを含む依存設定を再生成してください。環境設定へ登録する場合はinstall手順から`setup.sh`、開始手順から`run.sh`と配信確認を参照します。設定の保存、環境の公開、別タスクでの復元成功はそれぞれ別に確認します。

## GitHub経由での併用

作業前に`git status`と`git fetch`で状態を確認し、専用ブランチで作業します。Windowsとクラウドで同じブランチを同時編集せず、変更をcommit / pushして他方へ引き継ぎます。取り込み前に未コミット変更を保護し、SDK設定や依存が変わったらsetupを再実行します。commit・push・公開作業はAGENTS.mdの該当Skillに従ってください。

SDK、`.dart_tool`、Pubキャッシュ、生成物、秘密情報はGitに含めません。Windowsとクラウドのキャッシュをコピーせず、同じソースコミット・SDKコミット・lockfileから再生成します。アプリのブラウザ保存データもGit経由では同期されません。
