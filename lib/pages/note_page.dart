import 'package:flutter/material.dart';

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
              // タイトル入力
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
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 説明入力
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
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // カテゴリー入力
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
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 難易度（ドロップダウン）
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

              // フェーズ（1〜8）
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

              // LED数（1〜24）
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

              // 保存ボタン
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    showDialog(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: const Text('入力内容確認'),
                            content: Text(
                              'タイトル: $_title\n'
                              '説明: $_description\n'
                              'カテゴリー: $_category\n'
                              '難易度: $_difficulty\n'
                              'フェーズ: $_phase\n'
                              'LED数: $_ledCount',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
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
