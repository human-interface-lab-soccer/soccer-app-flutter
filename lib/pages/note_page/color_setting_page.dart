import 'package:flutter/material.dart';
import 'package:soccer_app_flutter/shared/enums/led_color.dart';
import 'package:soccer_app_flutter/shared/models/practice_menu.dart';

class ColorSettingPage extends StatefulWidget {
  final PracticeMenu practiceMenu;
  final bool isEditable;

  const ColorSettingPage({
    super.key,
    required this.practiceMenu,
    this.isEditable = false,
  });

  @override
  State<ColorSettingPage> createState() => _ColorSettingPageState();
}

class _ColorSettingPageState extends State<ColorSettingPage> {
  late List<List<LedColor>> colorSettings;

  final ScrollController _horizontalControllerHeader = ScrollController();
  final ScrollController _horizontalControllerData = ScrollController();
  final ScrollController _verticalControllerLeft = ScrollController();
  final ScrollController _verticalControllerData = ScrollController();

  @override
  void initState() {
    super.initState();
    // PracticeMenuから色設定を初期化
    colorSettings =
        widget.practiceMenu.colorSettings
            .map(
              (ledColors) =>
                  ledColors
                      .map((colorStr) => LedColor.fromLabel(colorStr))
                      .toList(),
            )
            .toList();

    // 横スクロールの同期
    _horizontalControllerHeader.addListener(() {
      if (_horizontalControllerData.offset !=
          _horizontalControllerHeader.offset) {
        _horizontalControllerData.jumpTo(_horizontalControllerHeader.offset);
      }
    });
    _horizontalControllerData.addListener(() {
      if (_horizontalControllerHeader.offset !=
          _horizontalControllerData.offset) {
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
    final selectedColor = colorSettings[ledIndex][phaseIndex];

    return Container(
      width: 120,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: selectedColor.displayColor.withValues(alpha: 0.3),
      ),
      child: DropdownButton<LedColor>(
        value: selectedColor,
        isExpanded: true,
        underline: const SizedBox(),
        items:
            LedColor.values
                .map(
                  (color) => DropdownMenuItem(
                    value: color,
                    child: Center(child: Text(color.label)),
                  ),
                )
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
        title: Text(
          widget.isEditable
              ? '${widget.practiceMenu.name} の色設定編集'
              : '${widget.practiceMenu.name} の色設定',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 編集モードの場合は説明を表示
          if (widget.isEditable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              color: Colors.blue.shade50,
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '編集モード：色設定を変更できます',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
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
                      widget.practiceMenu.phaseCount,
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
                      widget.practiceMenu.ledCount,
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
                        children: List.generate(widget.practiceMenu.ledCount, (
                          ledIndex,
                        ) {
                          return Row(
                            children: List.generate(
                              widget.practiceMenu.phaseCount,
                              (phaseIndex) {
                                return _buildDropdownCell(ledIndex, phaseIndex);
                              },
                            ),
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
          // LedColor → Stringに変換して保存
          final colorSettingsAsStrings =
              colorSettings
                  .map(
                    (ledColors) =>
                        ledColors.map((color) => color.label).toList(),
                  )
                  .toList();

          // 更新されたPracticeMenuオブジェクトを作成
          final updatedMenu = widget.practiceMenu.copyWith(
            colorSettings: colorSettingsAsStrings,
          );

          debugPrint('保存されたPracticeMenu: ${updatedMenu.toJson()}');

          // 更新されたPracticeMenuを返す
          Navigator.pop(context, updatedMenu);
        },
        label: Text(widget.isEditable ? '更新' : '保存'),
        icon: Icon(widget.isEditable ? Icons.check : Icons.save),
      ),
    );
  }
}
