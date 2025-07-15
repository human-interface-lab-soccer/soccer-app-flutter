import 'package:flutter/cupertino.dart';

// 時間ピッカーウィジェット
class TimePickerWidget extends StatelessWidget {
  final String title;
  final int initialMinutes;
  final int initialSeconds;
  final Function(int minutes, int seconds) onTimeChanged;

  const TimePickerWidget({
    super.key,
    required this.title,
    required this.initialMinutes,
    required this.initialSeconds,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 分ピッカー
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: initialMinutes,
                  ),
                  itemExtent: 32,
                  onSelectedItemChanged: (value) {
                    onTimeChanged(value, initialSeconds);
                  },
                  children: List.generate(
                    61,
                    (index) => Center(child: Text('$index')),
                  ),
                ),
              ),
              const Text(
                ':',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              // 秒ピッカー
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: initialSeconds,
                  ),
                  itemExtent: 32,
                  onSelectedItemChanged: (value) {
                    onTimeChanged(initialMinutes, value);
                  },
                  children: List.generate(
                    60,
                    (index) => Center(child: Text('$index')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
