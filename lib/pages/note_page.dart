import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/pages/note_page/color_setting_page.dart';

class NotePage extends StatefulWidget {
  const NotePage({super.key});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final _formKey = GlobalKey<FormState>();

  String _title = '';
  String _description = '';
  String _category = '';
  String _difficulty = '初級';
  int _phase = 1;
  int _ledCount = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key("notePage"),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('自由帳'),
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
                maxLength: 20,
                onSaved: (value) => _title = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  if (value.length > 20) {
                    return 'タイトルは20字以内で入力してください';
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

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'カテゴリー（10字以内）',
                  border: OutlineInputBorder(),
                ),
                maxLength: 10,
                onSaved: (value) => _category = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'カテゴリーを入力してください';
                  }
                  if (value.length > 10) {
                    return 'カテゴリーは10字以内で入力してください';
                  }
                  return null;
                },
              ),
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
                value: _phase,
                items: List.generate(
                  8,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) => setState(() => _phase = value!),
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    // 遷移時に入力内容を渡す
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ColorSettingPage(
                              title: _title,
                              description: _description,
                              category: _category,
                              difficulty: _difficulty,
                              phaseCount: _phase,
                              ledCount: _ledCount,
                            ),
                      ),
                    );
                  }
                },
                child: const Text('つぎへ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
