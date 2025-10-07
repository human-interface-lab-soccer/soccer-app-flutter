import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/enums/navigation_items.dart';

class MainNavigationBar extends StatefulWidget {
  const MainNavigationBar({super.key});

  @override
  State<MainNavigationBar> createState() => MainNavigationBarState();
}

class MainNavigationBarState extends State<MainNavigationBar> {
  int _selectedIndex = NavigationItems.connection.index; // デフォルトは接続画面（インデックス1）

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NavigationItems.values[_selectedIndex].page,
      bottomNavigationBar: BottomNavigationBar(
        items:
            NavigationItems.values.map((item) {
              return BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              );
            }).toList(),
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }
}
