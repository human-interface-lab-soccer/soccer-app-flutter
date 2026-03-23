# Soccer App Flutter

[![Flutter CI](https://github.com/human-interface-lab-soccer/soccer-app-flutter/actions/workflows/code_quality.yml/badge.svg)](https://github.com/human-interface-lab-soccer/soccer-app-flutter/actions/workflows/code_quality.yml)
[![Codemagic build status](https://api.codemagic.io/apps/6849443f0e1f7afe9a5b94c9/6849443f0e1f7afe9a5b94c8/status_badge.svg)](https://codemagic.io/app/6849443f0e1f7afe9a5b94c9/6849443f0e1f7afe9a5b94c8/latest_build)

## 主要機能
Coming soon...

## 技術スタック
- Flutter 3.29.3
- Dart 3.7.2
- Bluetooth Mesh Network
- Firebase App Distribution

## 環境構築手順
開発を始める前に，手元の環境をセットアップしてください．

1. **Flutter SDKのインストール**
2. **Gitのインストール**
3. **推奨IDE**: **VS Code** または **Android Studio** の使用を推奨します．それぞれのIDEでFlutter/Dartの拡張機能をインストールしてください
4. **シミュレータのインストール**: iOSアプリの動作確認には**Xcode**でiOSシミュレータを、Androidアプリの動作確認には**Android Studio**でAndroidエミュレータをインストールしてください。

### プロジェクトのクローンと初期設定
```bash
git clone git@github.com:human-interface-lab-soccer/soccer-app-flutter.git
cd soccer-app-flutter
flutter pub get
```

### アプリケーションの実行
プロジェクトのルートディレクトリで以下のコマンドを実行してください
```bash
flutter run
```
特定のデバイスIDで実行したい場合は `flutter run -d <device_id>` を使ってください

### テストの実行
コードの品質保持のため，定期的にテストを実行しましょう．
プロジェクト内のすべてのテストを実行するには，以下のコマンドを使用します
```bash
flutter test
```

## デバッグモード（`DEBUG`フラグ）

BLE関連のUI動作確認をシミュレータや実機で行うためのモックモードです。

### 有効化方法

`.env` ファイルで設定されています：
```
DEBUG=true
```
VS Codeからの起動時は `launch.json` の `--dart-define-from-file=.env` により自動で読み込まれます。
コマンドラインから直接指定する場合：
```bash
flutter run --dart-define=DEBUG=true
```

### 影響範囲

| ファイル | `DEBUG=true` の挙動 |
|---|---|
| `discovered_device_list.dart` | スキャン前にダミーBLEデバイス3台を初期表示する。スキャン開始後にストリームからデータが来ると、ダミーは実デバイスに置き換わる |
| `provisioning_progress_dialog.dart` | **ダミーデバイスを選択した場合のみ**モックプロビジョニング（2秒間隔で各ステップを擬似進行）を実行する。実デバイスを選択した場合は通常のBLEプロビジョニングが動作する |
| `network_node_list.dart` | ノードリスト取得時に1秒のローディング遅延を追加する |

### プロビジョニングのモック判定

モックプロビジョニングの実行はグローバルな`DEBUG`フラグではなく、**選択されたデバイスがダミーかどうか**で判定されます：

- **ダミーデバイス**（UUIDが `_testDevices` に一致） → モックプロビジョニング
- **実デバイス** → 通常のBLEプロビジョニング

そのため、`DEBUG=true` の状態で実機を接続しても、スキャンで検出された実デバイスは通常通りプロビジョニングできます。

## 貢献について
効果的なチーム開発のために，[CONTRIBUTING.md](https://github.com/human-interface-lab-soccer/soccer-app-flutter/blob/main/CONTRIBUTING.md) に記載されている開発ルール，ブランチ戦略などのガイドラインを必ず確認してください．
<!-- 川崎です -->
<!-- Hello world -->
