import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';
import 'package:soccer_app_flutter/shared/widgets/menu_item_widget.dart';

// メニューリスト
class MenuListWidget extends StatelessWidget {
  final List<PracticeMenu> menus;
  final Function(PracticeMenu) onMenuTap;

  const MenuListWidget({
    super.key,
    required this.menus,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return MenuItemWidget(menu: menu, onTap: () => onMenuTap(menu));
      },
    );
  }
}
