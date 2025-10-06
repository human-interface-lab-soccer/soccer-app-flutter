import 'package:flutter/material.dart';

class ColorSettingPage extends StatefulWidget {
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int phaseCount;
  final int ledCount;

  const ColorSettingPage({
    super.key,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.phaseCount,
    required this.ledCount,
  });

  @override
  State<ColorSettingPage> createState() => _ColorSettingPageState();
}

class _ColorSettingPageState extends State<ColorSettingPage> {
  late List<List<String>> colorSettings;
  final List<String> colors = ['赤', '青', '緑', 'クリア'];
  
  final ScrollController _horizontalControllerHeader = ScrollController();
  final ScrollController _horizontalControllerData = ScrollController();
  final ScrollController _verticalControllerLeft = ScrollController();
  final ScrollController _verticalControllerData = ScrollController();

  @override
  void initState() {
    super.initState();
    colorSettings = List.generate(
      widget.ledCount,
      (_) => List.generate(widget.phaseCount, (_) => 'クリア'),
    );
    
    // 横スクロールの同期
    _horizontalControllerHeader.addListener(() {
      if (_horizontalControllerData.offset != _horizontalControllerHeader.offset) {
        _horizontalControllerData.jumpTo(_horizontalControllerHeader.offset);
      }
    });
    _horizontalControllerData.addListener(() {
      if (_horizontalControllerHeader.offset != _horizontalControllerData.offset) {
        _horizontalControllerHeader.jumpTo(_horizontalControllerData.offset);
      }
    });
    
    // 縦スクロールの同期
    _verticalControllerLeft.addListener(() {
      if (_verticalControllerData.offset != _verticalControllerLeft.offset) {
        _verticalControllerData.jumpTo(_verticalControllerLeft.offset);
      }
    });
    _verticalControllerData.addListener(() {
      if (_verticalControllerLeft.offset != _verticalControllerData.offset) {
        _verticalControllerLeft.jumpTo(_verticalControllerData.offset);
      }
    });
  }

  @override
  void dispose() {
    _horizontalControllerHeader.dispose();
    _horizontalControllerData.dispose();
    _verticalControllerLeft.dispose();
    _verticalControllerData.dispose();
    super.dispose();
  }

  // 色に対応するColorオブジェクトを返す
  Color getColorFromString(String colorName) {
    switch (colorName) {
      case '赤':
        return Colors.red.shade100;
      case '青':
        return Colors.blue.shade100;
      case '緑':
        return Colors.green.shade100;
      default:
        return Colors.transparent;
    }
  }

  Widget _buildCell(String value, {bool isHeader = false}) {
    return Container(
      width: 120,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: isHeader ? Colors.grey.shade200 : Colors.white,
      ),
      child: Text(
        value,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDropdownCell(int ledIndex, int phaseIndex) {
    return Container(
      width: 120,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: getColorFromString(colorSettings[ledIndex][phaseIndex]),
      ),
      child: DropdownButton<String>(
        value: colorSettings[ledIndex][phaseIndex],
        isExpanded: true,
        underline: const SizedBox(),
        items: colors
            .map((c) => DropdownMenuItem(
                  value: c,
                  child: Center(child: Text(c)),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            colorSettings[ledIndex][phaseIndex] = value!;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} の色設定'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 固定ヘッダー行
          Row(
            children: [
              // 左上の固定セル（LED番号ラベル）
              _buildCell('LED番号', isHeader: true),
              // ヘッダー行（横スクロール可能）
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _horizontalControllerHeader,
                  child: Row(
                    children: List.generate(
                      widget.phaseCount,
                      (index) => _buildCell('P${index + 1}', isHeader: true),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // データ行（縦横スクロール可能）
          Expanded(
            child: Row(
              children: [
                // 固定列（LED番号，縦スクロール可能）
                SingleChildScrollView(
                  controller: _verticalControllerLeft,
                  child: Column(
                    children: List.generate(
                      widget.ledCount,
                      (ledIndex) => _buildCell('LED${ledIndex + 1}'),
                    ),
                  ),
                ),
                // スクロール可能なデータ部分
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _horizontalControllerData,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      controller: _verticalControllerData,
                      child: Column(
                        children: List.generate(widget.ledCount, (ledIndex) {
                          return Row(
                            children: List.generate(widget.phaseCount, (phaseIndex) {
                              return _buildDropdownCell(ledIndex, phaseIndex);
                            }),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          debugPrint('色設定データ: $colorSettings');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('設定を保存しました')),
          );
          Navigator.pop(context);
        },
        label: const Text('保存'),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
