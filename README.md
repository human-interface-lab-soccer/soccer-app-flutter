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

## 貢献について
効果的なチーム開発のために，[CONTRIBUTING.md](https://github.com/human-interface-lab-soccer/soccer-app-flutter/blob/main/CONTRIBUTING.md) に記載されている開発ルール，ブランチ戦略などのガイドラインを必ず確認してください．
