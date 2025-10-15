import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soccer_app_flutter/pages/note_page/menu_form_page.dart';

/// 自由帳ページ（新規作成専用）
/// 実体はMenuFormPageで，existingMenuをnullにして新規作成モードで使用
class NotePage extends ConsumerWidget {
  const NotePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // MenuFormPageを新規作成モードで表示
    return const MenuFormPage(existingMenu: null);
  }
}
