import 'package:vibration/vibration.dart';

class HapticFeedbackManager {
  static Future<void> triggerCardTakeVibration() async {
    // Check if device supports vibration
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      // Medium vibration when taking cards
      await Vibration.vibrate(duration: 100, amplitude: 128);
    }
  }

  static Future<void> triggerLightVibration() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      // Light vibration for card play
      await Vibration.vibrate(duration: 50, amplitude: 64);
    }
  }

  static Future<void> triggerHeavyVibration() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      // Heavy vibration for game win
      await Vibration.vibrate(duration: 200, amplitude: 255);
    }
  }
}
