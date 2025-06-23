import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/pages/menu_page.dart';
import 'package:soccer_app_flutter/pages/connection_page.dart';
import 'package:soccer_app_flutter/pages/note_page.dart';

enum NavigationItems {
  menu(Icons.menu_book, "メニュー", MenuPage()),
  connection(Icons.bluetooth_connected, "接続", ConnectionPage()),
  note(Icons.settings, "自由帳", NotePage());

  final IconData icon;
  final String label;
  final Widget page;

  const NavigationItems(this.icon, this.label, this.page);
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => MainNavigationPageState();
}

class MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = NavigationItems.connection.index; // デフォルトは接続画面（インデックス1）

  void _onItemTapped(int index) {
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
        onTap: _onItemTapped,
      ),
    );
  }
}
