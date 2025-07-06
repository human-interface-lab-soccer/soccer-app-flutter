// 時間に関するユーティリティクラス
class TimeUtils {
  // 秒数を分と秒に変換するヘルパーメソッド
  static String formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // 分と秒を秒数に変換するヘルパーメソッド
  static int getTotalSeconds(int minutes, int seconds) {
    return (minutes * 60) + seconds;
  }
}
