enum AISlapSpeed { slow, medium, fast }

final soundEnabledPrefsKey = 'sound_enabled';
final aiSlapSpeedPrefsKey = 'ai_slap_speed';
final badSlapPenaltyPrefsKey = 'bad_slap_penalty';

String prefsKeyForVariation(dynamic v) {
  return 'rule.${v.toString()}';
}
