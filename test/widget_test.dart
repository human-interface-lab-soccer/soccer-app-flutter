import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_app_flutter/pages/main_navigation_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soccer_app_flutter/shared/providers/practice_menu_provider.dart';
import 'package:soccer_app_flutter/shared/providers/menu_filter_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() {
  // テスト開始前にHiveを初期化
  setUpAll(() async {
    // テスト用の一時ディレクトリを作成
    final testDir = Directory.systemTemp.createTempSync('hive_test');

    // Hiveを初期化
    Hive.init(testDir.path);

    // テスト用のボックスを開く
    try {
      await Hive.openBox('practice_menus');
      await Hive.openBox('app_settings');
    } catch (e) {
      // 既に開かれている場合は無視
      debugPrint('Hive box already open: $e');
    }
  });

  // 各テスト後にボックスをクリア
  tearDown(() async {
    try {
      final box = Hive.box('practice_menus');
      await box.clear();
      final settingsBox = Hive.box('app_settings');
      await settingsBox.clear();
    } catch (e) {
      debugPrint('Failed to clear box: $e');
    }
  });

  // テスト終了後にクリーンアップ
  tearDownAll(() async {
    try {
      await Hive.close();
    } catch (e) {
      debugPrint('Failed to close Hive: $e');
    }
  });

  testWidgets('MainNavigationBar 初期状態はメニューページ', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MainNavigationBar())),
    );

    // 初期状態でメニューページが表示される
    expect(find.byKey(const Key('menuPage')), findsOneWidget);
  });

  testWidgets('BottomNavigationBarで各ページへ遷移', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // プロバイダーをモック化してエラーを防ぐ
          isLoadingProvider.overrideWith((ref) => false),
          errorMessageProvider.overrideWith((ref) => null),
          filteredMenusProvider.overrideWith((ref) => []),
        ],
        child: const MaterialApp(home: MainNavigationBar()),
      ),
    );

    // 初期状態を確認
    expect(find.byKey(const Key('menuPage')), findsOneWidget);

    // メニューページに遷移
    final menuIcon = find.byIcon(Icons.menu_book);
    expect(menuIcon, findsOneWidget);
    await tester.tap(menuIcon);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menuPage')), findsOneWidget);

    // 自由帳ページに遷移
    final noteIcon = find.byIcon(Icons.edit_note);
    expect(noteIcon, findsOneWidget);
    await tester.tap(noteIcon);
    await tester.pumpAndSettle();
    // MenuFormPageのキーを確認
    expect(find.byKey(const Key('menuFormPage')), findsOneWidget);

    // 設定ページに遷移
    final settingsIcon = find.byIcon(Icons.settings);
    expect(settingsIcon, findsOneWidget);
    await tester.tap(settingsIcon);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settingPage')), findsOneWidget);

    // 接続ページに遷移
    final connectionIcon = find.byIcon(Icons.bluetooth_connected);
    expect(connectionIcon, findsOneWidget);
    await tester.tap(connectionIcon);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('connectionPage')), findsOneWidget);
  });

  testWidgets('自由帳ページでフォームが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isLoadingProvider.overrideWith((ref) => false),
          errorMessageProvider.overrideWith((ref) => null),
          allMenusProvider.overrideWith((ref) => []),
        ],
        child: const MaterialApp(home: MainNavigationBar()),
      ),
    );

    // 自由帳ページに遷移
    await tester.tap(find.byIcon(Icons.edit_note));
    await tester.pumpAndSettle();

    // フォームの要素が存在することを確認
    expect(find.text('タイトル（20字以内）'), findsOneWidget);
    expect(find.text('説明（50字以内）'), findsOneWidget);
    expect(find.text('カテゴリー（10字以内）'), findsOneWidget);
    expect(find.text('難易度'), findsOneWidget);
    expect(find.text('フェーズ（1〜8）'), findsOneWidget);
    expect(find.text('LED数（1〜24）'), findsOneWidget);
  });

  group('ConnectionPage内のボタン挙動確認', () {
    Future<void> pumpConnectionPage(WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: MainNavigationBar())),
      );
      await tester.tap(find.byIcon(Icons.bluetooth_connected));
      await tester.pumpAndSettle();
    }

    testWidgets('赤ボタンをタップするとメッセージが表示される', (WidgetTester tester) async {
      await pumpConnectionPage(tester);
      // 初期状態ではメッセージが表示されていないことを確認
      expect(find.text('赤だよー'), findsNothing);

      // 赤ボタンをタップ
      await tester.tap(find.byKey(const Key("redButton")));
      await tester.pump();

      // メッセージが表示されていることを確認
      expect(find.text('赤だよー'), findsOneWidget);
    });
    testWidgets('青ボタンをタップするとメッセージが表示される', (WidgetTester tester) async {
      await pumpConnectionPage(tester);

      // 初期状態ではメッセージが表示されていないことを確認
      expect(find.text('青だよー'), findsNothing);

      // 青ボタンをタップ
      await tester.tap(find.byKey(const Key("blueButton")));
      await tester.pump();

      // メッセージが表示されていることを確認
      expect(find.text('青だよー'), findsOneWidget);
    });
    testWidgets('緑ボタンをタップするとメッセージが表示される', (WidgetTester tester) async {
      await pumpConnectionPage(tester);

      // 初期状態ではメッセージが表示されていないことを確認
      expect(find.text('緑だよー'), findsNothing);

      // 緑ボタンをタップ
      await tester.tap(find.byKey(const Key("greenButton")));
      await tester.pump();

      // メッセージが表示されていることを確認
      expect(find.text('緑だよー'), findsOneWidget);
    });
    testWidgets('クリアボタンをタップするとメッセージが消える', (WidgetTester tester) async {
      await pumpConnectionPage(tester);

      // 赤ボタンをタップしてメッセージを表示
      await tester.tap(find.byKey(const Key("redButton")));
      await tester.pump();
      expect(find.text('赤だよー'), findsOneWidget);

      // クリアボタンをタップ
      await tester.tap(find.byKey(const Key("clearButton")));
      await tester.pump();

      // メッセージが消えていることを確認
      expect(find.text('赤だよー'), findsNothing);
    });
    testWidgets('接続ボタンをタップするとメッセージが表示される', (WidgetTester tester) async {
      await pumpConnectionPage(tester);

      // 初期状態ではメッセージが表示されていないことを確認
      expect(find.text('デバイスのスキャン'), findsNothing);

      // 接続ボタンをタップ
      await tester.tap(find.byKey(const Key("connectButton")));
      await tester.pump();

      // メッセージが表示されていることを確認
      expect(find.text('デバイスのスキャン'), findsOneWidget);
    });
    testWidgets('グループ決定ボタンをタップするとメッセージが表示される', (WidgetTester tester) async {
      await pumpConnectionPage(tester);

      // 初期状態ではメッセージが表示されていないことを確認
      expect(find.text('グループ決定!!'), findsNothing);

      // グループ決定ボタンをタップ
      await tester.tap(find.byKey(const Key("decideGroupButton")));
      await tester.pump();

      // メッセージが表示されていることを確認
      expect(find.text('グループ決定!!'), findsOneWidget);
    });
    testWidgets('接続確認ボタンをタップするとデバイスリストが表示される', (WidgetTester tester) async {
      await pumpConnectionPage(tester);

      // 初期状態ではデバイス名は表示されていない
      expect(find.text('デバイス確認'), findsNothing);
      expect(find.text('デバイスA'), findsNothing);
      expect(find.text('デバイスB'), findsNothing);
      expect(find.text('デバイスC'), findsNothing);

      // デバイス確認ボタンをタップ
      await tester.tap(find.byKey(const Key("checkDeviceButton")));
      await tester.pump();

      // デバイスリストが更新されていることを確認
      expect(find.text('デバイスA'), findsOneWidget);
      expect(find.text('デバイスB'), findsOneWidget);
      expect(find.text('デバイスC'), findsOneWidget);

      // メッセージが表示されていることを確認
      expect(find.text('デバイス確認'), findsOneWidget);
    });
  });
}
