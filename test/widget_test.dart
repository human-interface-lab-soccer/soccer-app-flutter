import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_app_flutter/pages/main_navigation_page.dart';

void main() {
  testWidgets('MainNavigationPage 初期状態は接続ページ', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainNavigationPage()));
    expect(find.byKey(const Key('connectionPage')), findsOneWidget);
  });
  testWidgets('BottomNavigationBarで各ページへ遷移', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainNavigationPage()));

    await tester.tap(find.byIcon(Icons.menu_book));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menuPage')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notePage')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bluetooth_connected));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('connectionPage')), findsOneWidget);
  });

  group('ConnectionPage内のボタン挙動確認', () {
    Future<void> pumpConnectionPage(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainNavigationPage()));
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
