import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/utils/color_helpers.dart';

// メニューアイテムのウィジェット
class MenuItemWidget extends StatelessWidget {
  final PracticeMenu menu;
  final VoidCallback onTap;

  const MenuItemWidget({
    super.key,
    required this.menu,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          menu.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(menu.description),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTag(
                  menu.category,
                  Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                _buildTag(
                  menu.type,
                  ColorHelpers.getTypeColor(menu.type),
                ),
                const SizedBox(width: 8),
                _buildTag(
                  menu.difficulty,
                  ColorHelpers.getDifficultyColor(menu.difficulty),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}
