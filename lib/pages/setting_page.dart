import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soccer_app_flutter/shared/providers/theme_provider.dart';

class SettingPage extends ConsumerWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeColor = ref.watch(themeColorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'テーマカラー',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...ThemeColorOption.values.map((option) {
            final isSelected = option == currentThemeColor;
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: option.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child:
                    isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
              ),
              title: Text(option.label),
              trailing:
                  isSelected
                      ? Icon(Icons.radio_button_checked, color: option.color)
                      : const Icon(Icons.radio_button_unchecked),
              onTap: () {
                ref.read(themeColorProvider.notifier).setThemeColor(option);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
