import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/utils/color_helpers.dart';
import 'package:soccer_app_flutter/shared/widgets/tag_widget.dart';

/// メニュー情報を表示するカードウィジェット
class MenuInfoCard extends StatelessWidget {
  final PracticeMenu menu;

  const MenuInfoCard({super.key, required this.menu});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 8),
          _buildDescription(),
          const SizedBox(height: 16),
          _buildTags(context),
        ],
      ),
    );
  }

  /// タイトル部分の構築
  Widget _buildTitle() {
    return Text(
      menu.name,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  /// 説明文部分の構築
  Widget _buildDescription() {
    return Text(menu.description, style: const TextStyle(fontSize: 16));
  }

  /// タグ部分の構築
  Widget _buildTags(BuildContext context) {
    return Row(
      children: [
        TagWidget(
          text: menu.category,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        TagWidget(text: menu.type, color: ColorHelpers.getTypeColor(menu.type)),
        const SizedBox(width: 8),
        TagWidget(
          text: menu.difficulty,
          color: ColorHelpers.getDifficultyColor(menu.difficulty),
        ),
      ],
    );
  }
}
