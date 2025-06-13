// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:soccer_app_flutter/main.dart';

void main() {
  testWidgets('赤ボタンをタップするとメッセージが表示される', (WidgetTester tester) async {
    // アプリをビルドしてフレームを描画
    await tester.pumpWidget(const MyApp());

    // 初期状態ではメッセージが表示されていないことを確認
    expect(find.text('赤だよー'), findsNothing);

    // 赤ボタンをタップ
    await tester.tap(find.text('赤'));
    await tester.pump();

    // メッセージが表示されていることを確認
    expect(find.text('赤だよー'), findsOneWidget);
  });
  testWidgets('青ボタンをタップするとメッセージが表示される', (WidgetTester tester) async {
    // アプリをビルドしてフレームを描画
    await tester.pumpWidget(const MyApp());

    // 初期状態ではメッセージが表示されていないことを確認
    expect(find.text('青だよー'), findsNothing);

    // 青ボタンをタップ
    await tester.tap(find.text('青'));
    await tester.pump();

    // メッセージが表示されていることを確認
    expect(find.text('青だよー'), findsOneWidget);
  });
  testWidgets('緑ボタンをタップするとメッセージが表示される', (WidgetTester tester) async {
    // アプリをビルドしてフレームを描画
    await tester.pumpWidget(const MyApp());

    // 初期状態ではメッセージが表示されていないことを確認
    expect(find.text('緑だよー'), findsNothing);

    // 緑ボタンをタップ
    await tester.tap(find.text('緑'));
    await tester.pump();

    // メッセージが表示されていることを確認
    expect(find.text('緑だよー'), findsOneWidget);
  });
  testWidgets('クリアボタンをタップするとメッセージが消える', (WidgetTester tester) async {
    // アプリをビルドしてフレームを描画
    await tester.pumpWidget(const MyApp());

    // 赤ボタンをタップしてメッセージを表示
    await tester.tap(find.text('赤'));
    await tester.pump();
    expect(find.text('赤だよー'), findsOneWidget);

    // クリアボタンをタップ
    await tester.tap(find.text('クリア'));
    await tester.pump();

    // メッセージが消えていることを確認
    expect(find.text('赤だよー'), findsNothing);
  });
  testWidgets('接続ボタンをタップするとデバイスリストが更新される', (WidgetTester tester) async {
    // アプリをビルドしてフレームを描画
    await tester.pumpWidget(const MyApp());

    // 初期状態ではメッセージが表示されていないことを確認
    expect(find.text('デバイス接続'), findsNothing);

    // 接続ボタンをタップ
    await tester.tap(find.text('接続'));
    await tester.pump();

    // デバイスリストが更新されていることを確認
    expect(find.text('デバイス接続'), findsOneWidget);
  });
  testWidgets('グループ決定ボタンをタップするとメッセージが表示される', (WidgetTester tester) async {
    // アプリをビルドしてフレームを描画
    await tester.pumpWidget(const MyApp());

    // 初期状態ではメッセージが表示されていないことを確認
    expect(find.text('グループ決定！！'), findsNothing);

    // グループ決定ボタンをタップ
    await tester.tap(find.text('グループの決定'));
    await tester.pump();

    // メッセージが表示されていることを確認
    expect(find.text('グループ確定！！'), findsOneWidget);
  });
  testWidgets('デバイス確認ボタンをタップするとデバイスリストが更新される', (WidgetTester tester) async {
    // アプリをビルドしてフレームを描画
    await tester.pumpWidget(const MyApp());

    // 初期状態ではデバイス名は表示されていない
    expect(find.text('デバイスA'), findsNothing);
    expect(find.text('デバイスB'), findsNothing);
    expect(find.text('デバイスC'), findsNothing);

    // デバイス確認ボタンをタップ
    await tester.tap(find.text('接続確認'));
    await tester.pump();

    // デバイスリストが更新されていることを確認
    expect(find.text('デバイスA'), findsOneWidget);
    expect(find.text('デバイスB'), findsOneWidget);
    expect(find.text('デバイスC'), findsOneWidget);

    // メッセージが表示されていることを確認
    expect(find.text('デバイス確認'), findsOneWidget);
  });
}
