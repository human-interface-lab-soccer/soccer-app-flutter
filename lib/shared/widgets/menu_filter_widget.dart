import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/service/practice_menu_service.dart';

// メニューのフィルタリングウィジェット
class MenuFilterWidget extends StatelessWidget {
  final String selectedCategory;
  final String selectedType;
  final String selectedDifficulty;
  final Function(String) onCategoryChanged;
  final Function(String) onTypeChanged;
  final Function(String) onDifficultyChanged;

  const MenuFilterWidget({
    super.key,
    required this.selectedCategory,
    required this.selectedType,
    required this.selectedDifficulty,
    required this.onCategoryChanged,
    required this.onTypeChanged,
    required this.onDifficultyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // カテゴリ選択ドロップダウン
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('カテゴリ'),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  items:
                      ['すべて', ...PracticeMenuService.getCategories()]
                          .map(
                            (String category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      onCategoryChanged(newValue);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // タイプ選択ドロップダウン
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('タイプ'),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: selectedType,
                  isExpanded: true,
                  items:
                      ['すべて', ...PracticeMenuService.getTypes()]
                          .map(
                            (String type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      onTypeChanged(newValue);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 難易度選択ドロップダウン
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('難易度'),
                const SizedBox(height: 4),
                DropdownButton<String>(
                  value: selectedDifficulty,
                  isExpanded: true,
                  items:
                      ['すべて', ...PracticeMenuService.getDifficulties()]
                          .map(
                            (String difficulty) => DropdownMenuItem<String>(
                              value: difficulty,
                              child: Text(difficulty),
                            ),
                          )
                          .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      onDifficultyChanged(newValue);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
