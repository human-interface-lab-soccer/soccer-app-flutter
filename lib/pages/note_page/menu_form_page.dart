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
  final _categoryController = TextEditingController();

  late String _name;
  late String _description;
  late String _category;
  late String _difficulty;
  late int _phaseCount;
  late int _ledCount;

  /// カテゴリーのカスタム入力モードかどうか
  bool _isCustomCategory = false;

  /// ドロップダウンの「新しいカテゴリーを入力」項目を識別するための特殊な値
  static const String _customCategoryValue = '__custom__';

  /// 編集モードかどうか
  bool get isEditMode => widget.existingMenu != null;

  @override
  void initState() {
    super.initState();
    // 編集モードの場合は既存の値で初期化
    final menu = widget.existingMenu;
    if (isEditMode && menu != null) {
      _name = menu.name;
      _description = menu.description;
      _category = menu.category;
      _difficulty = menu.difficulty;
      _phaseCount = menu.phaseCount;
      _ledCount = menu.ledCount;

      /// 既存のカテゴリーかどうかをチェック
      final existingCategories = _getExistingCategories();
      if (!existingCategories.contains(_category)) {
        _isCustomCategory = true;
        _categoryController.text = _category;
      }
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
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  /// 既存のカテゴリーリストを取得
  List<String> _getExistingCategories() {
    final allMenus = ref.read(allMenusProvider);
    final categories = allMenus
        .map((menu) => menu.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  /// カテゴリー入力フィールドを構築
  Widget _buildCategoryField(List<String> existingCategories) {
    if (_isCustomCategory) {
      // カスタム入力モード
      return TextFormField(
        controller: _categoryController,
        decoration: InputDecoration(
          labelText: 'カテゴリー（10字以内）',
          border: const OutlineInputBorder(),
          suffixIcon: existingCategories.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.arrow_drop_down),
                  onPressed: () {
                    setState(() {
                      // 入力された値を_categoryに保存
                      _category = _categoryController.text;
                      _isCustomCategory = false;
                      // 入力された値が既存カテゴリーにない場合は，空にしてバリデーションで対応
                      if (!existingCategories.contains(_category)) {
                        _category = '';
                      }
                    });
                  },
                )
              : null,
        ),
        maxLength: 10,
        onChanged: (value) => _category = value,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'カテゴリーを入力してください';
          }
          if (value.length > 10) {
            return 'カテゴリーは10字以内で入力してください';
          }
          return null;
        },
      );
    } else {
      // ドロップダウン選択モード
      final dropdownItems = [
        ...existingCategories.map(
          (category) => DropdownMenuItem(
            value: category,
            child: Text(category),
          ),
        ),
        const DropdownMenuItem(
          value: _customCategoryValue,
          child: Row(
            children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 8),
              Text('新しいカテゴリーを入力'),
            ],
          ),
        ),
      ];
      return DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'カテゴリー',
          border: OutlineInputBorder(),
        ),
        value: existingCategories.contains(_category)
            ? _category
            : null,
        items: dropdownItems,
        onChanged: (value) {
          if (value == _customCategoryValue) {
            setState(() {
              _isCustomCategory = true;
              _categoryController.clear();
              _category = '';
            });
          } else {
            setState(() {
              _category = value!;
            });
          }
        },
        validator: (value) {
          if (!_isCustomCategory && (value == null || value.isEmpty)) {
            return 'カテゴリーを選択してください';
          }
          return null;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingCategories = _getExistingCategories();

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

              // カテゴリー入力フィールド(ドロップダウンとテキスト入力の切り替え）
              _buildCategoryField(existingCategories),
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
                          isEditMode
                              ? widget.existingMenu!.colorSettings
                              : null,
                    );

                    // ColorSettingPageに遷移（編集モードフラグを渡す）
                    final updatedMenu = await Navigator.push<PracticeMenu>(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ColorSettingPage(
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

                        // メニューページに戻る（2つ前の画面）
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
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
