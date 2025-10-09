import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soccer_app_flutter/pages/note_page/color_setting_page.dart';
import 'package:soccer_app_flutter/shared/enums/navigation_items.dart';
import 'package:soccer_app_flutter/pages/main_navigation_bar.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/providers/practice_menu_provider.dart';

class NotePage extends ConsumerStatefulWidget {
  const NotePage({super.key});

  @override
  ConsumerState<NotePage> createState() => _NotePageState();
}

class _NotePageState extends ConsumerState<NotePage> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _description = '';
  String _category = '';
  String _difficulty = '初級';
  int _phaseCount = 1;
  int _ledCount = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key("notePage"),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('自由帳'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'タイトル（20字以内）',
                  border: OutlineInputBorder(),
                ),
                maxLength: 20,
                onSaved: (value) => _name = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  if (value.length > 20) {
                    return 'タイトルは20字以内で入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: '説明（50字以内）',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
                onSaved: (value) => _description = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '説明を入力してください';
                  }
                  if (value.length > 50) {
                    return '説明は50字以内で入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'カテゴリー（10字以内）',
                  border: OutlineInputBorder(),
                ),
                maxLength: 10,
                onSaved: (value) => _category = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'カテゴリーを入力してください';
                  }
                  if (value.length > 10) {
                    return 'カテゴリーは10字以内で入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '難易度',
                  border: OutlineInputBorder(),
                ),
                value: _difficulty,
                items:
                    ['初級', '中級', '上級']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (value) => setState(() => _difficulty = value!),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'フェーズ（1〜8）',
                  border: OutlineInputBorder(),
                ),
                value: _phaseCount,
                items: List.generate(
                  8,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) => setState(() => _phaseCount = value!),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'LED数（1〜24）',
                  border: OutlineInputBorder(),
                ),
                value: _ledCount,
                items: List.generate(
                  24,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) => setState(() => _ledCount = value!),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    // PracticeMenuオブジェクトを作成
                    final practiceMenu = PracticeMenu(
                      name: _name,
                      description: _description,
                      category: _category,
                      type: '自由帳',
                      difficulty: _difficulty,
                      phaseCount: _phaseCount,
                      ledCount: _ledCount,
                    );

                    // ColorSettingPageに遷移
                    final updatedMenu = await Navigator.push<PracticeMenu>(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ColorSettingPage(practiceMenu: practiceMenu),
                      ),
                    );

                    // 保存が完了した場合，メニュー画面に戻る
                    if (updatedMenu != null) {
                      // ✅ Hiveへ保存
                      await ref
                          .read(practiceMenuProvider.notifier)
                          .addMenu(updatedMenu);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('練習メニューを保存しました')),
                      );
                      // ここでデータベースに保存する処理を追加可能
                      // 例: await savePracticeMenu(updatedMenu);

                      mainNavigationBarKey.currentState?.onItemTapped(
                        NavigationItems.menu.index,
                      );
                    }
                  }
                },
                child: const Text('つぎへ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
