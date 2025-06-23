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
  int _selectedIndex = 1; // デフォルトは接続画面（インデックス1）

  final List<Widget> _pages = [
    const MenuPage(),
    const ConnectionPage(),
    const NotePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'メニュー'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth_connected),
            label: '接続',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '自由帳'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
