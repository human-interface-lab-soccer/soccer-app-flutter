import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soccer_app_flutter/pages/note_page/color_setting_page.dart';
import 'package:soccer_app_flutter/shared/enums/navigation_items.dart';
import 'package:soccer_app_flutter/pages/main_navigation_bar.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/providers/practice_menu_provider.dart';

/// 練習メニューの新規作成・編集ページ
class MenuFormPage extends ConsumerStatefulWidget {
  /// 編集モードの場合は既存のメニューを渡す
  final PracticeMenu? existingMenu;

  const MenuFormPage({super.key, this.existingMenu});

  @override
  ConsumerState<MenuFormPage> createState() => _MenuFormPageState();
}

class _MenuFormPageState extends ConsumerState<MenuFormPage> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _description;
  late String _category;
  late String _difficulty;
  late int _phaseCount;
  late int _ledCount;

  /// 編集モードかどうか
  bool get isEditMode => widget.existingMenu != null;

  @override
  void initState() {
    super.initState();
    // 編集モードの場合は既存の値で初期化
    if (isEditMode) {
      _name = widget.existingMenu!.name;
      _description = widget.existingMenu!.description;
      _category = widget.existingMenu!.category;
      _difficulty = widget.existingMenu!.difficulty;
      _phaseCount = widget.existingMenu!.phaseCount;
      _ledCount = widget.existingMenu!.ledCount;
    } else {
      // 新規作成モードの場合はデフォルト値
      _name = '';
      _description = '';
      _category = '';
      _difficulty = '初級';
      _phaseCount = 1;
      _ledCount = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key("menuFormPage"),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(isEditMode ? 'メニューの編集' : '自由帳'),
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
                initialValue: _name,
                maxLength: 20,
                onSaved: (value) => _name = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  if (value.length > 20) {
                    return 'タイトルは20字以内で入力してください';
                  }
                  // タイトル重複チェック（編集時は自分自身を除く）
                  final allMenus = ref.read(allMenusProvider);
                  final isDuplicate = allMenus.any(
                    (menu) =>
                        menu.name == value &&
                        (!isEditMode || menu.id != widget.existingMenu!.id),
                  );
                  if (isDuplicate) {
                    return 'このタイトルは既に存在します';
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
                initialValue: _description,
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
                initialValue: _category,
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
                items: ['初級', '中級', '上級']
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

                    // PracticeMenuオブジェクトを作成（編集時はIDを保持）
                    final practiceMenu = PracticeMenu(
                      id: isEditMode ? widget.existingMenu!.id : null,
                      name: _name,
                      description: _description,
                      category: _category,
                      type: '自由帳',
                      difficulty: _difficulty,
                      phaseCount: _phaseCount,
                      ledCount: _ledCount,
                      // 編集時は既存の色設定を保持
                      colorSettings:
                          isEditMode ? widget.existingMenu!.colorSettings : null,
                    );

                    // ColorSettingPageに遷移（編集モードフラグを渡す）
                    final updatedMenu = await Navigator.push<PracticeMenu>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ColorSettingPage(
                          practiceMenu: practiceMenu,
                          isEditable: isEditMode,
                        ),
                      ),
                    );

                    if (!context.mounted) return;

                    // 保存が完了した場合
                    if (updatedMenu != null) {
                      if (isEditMode) {
                        // 編集モード：更新処理
                        await ref
                            .read(practiceMenuProvider.notifier)
                            .updateMenu(updatedMenu);

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('練習メニューを更新しました')),
                        );

                        // 詳細ページに戻る（2つ前の画面）
                        Navigator.pop(context);
                        Navigator.pop(context);
                      } else {
                        // 新規作成モード：追加処理
                        await ref
                            .read(practiceMenuProvider.notifier)
                            .addMenu(updatedMenu);

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('練習メニューを保存しました')),
                        );

                        mainNavigationBarKey.currentState?.onItemTapped(
                          NavigationItems.menu.index,
                        );
                      }
                    }
                  }
                },
                child: Text(isEditMode ? '更新' : 'つぎへ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}