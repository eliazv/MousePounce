import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'soundeffects.dart';
import 'game.dart';
import 'types.dart';

/// Shows the preferences bottom sheet. When closed, calls onClose callback.
Future<void> showPreferencesBottomSheet(
  BuildContext context,
  Size displaySize, {
  required SharedPreferences preferences,
  required Game game,
  required AISlapSpeed aiSlapSpeed,
  required Function(AISlapSpeed) onAiSlapSpeedChanged,
  required Function(bool) onSoundEnabledChanged,
  required Function(bool) onMusicEnabledChanged,
  required SoundEffectPlayer soundPlayer,
  required VoidCallback onClose,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    barrierColor: Colors.transparent,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _PreferencesBottomSheetContent(
        displaySize: displaySize,
        preferences: preferences,
        game: game,
        aiSlapSpeed: aiSlapSpeed,
        onAiSlapSpeedChanged: onAiSlapSpeedChanged,
        onSoundEnabledChanged: onSoundEnabledChanged,
        onMusicEnabledChanged: onMusicEnabledChanged,
        soundPlayer: soundPlayer,
        onClose: onClose,
      );
    },
  ).then((_) => onClose());
}

class _PreferencesBottomSheetContent extends StatefulWidget {
  final Size displaySize;
  final SharedPreferences preferences;
  final Game game;
  final AISlapSpeed aiSlapSpeed;
  final Function(AISlapSpeed) onAiSlapSpeedChanged;
  final Function(bool) onSoundEnabledChanged;
  final Function(bool) onMusicEnabledChanged;
  final SoundEffectPlayer soundPlayer;
  final VoidCallback onClose;

  const _PreferencesBottomSheetContent({
    required this.displaySize,
    required this.preferences,
    required this.game,
    required this.aiSlapSpeed,
    required this.onAiSlapSpeedChanged,
    required this.onSoundEnabledChanged,
    required this.onMusicEnabledChanged,
    required this.soundPlayer,
    required this.onClose,
  });

  @override
  State<_PreferencesBottomSheetContent> createState() =>
      _PreferencesBottomSheetContentState();
}

class _PreferencesBottomSheetContentState
    extends State<_PreferencesBottomSheetContent> {
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4, right: 16, top: 4, bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2),
              letterSpacing: 0.5,
            ),
          ),
          Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(0xFF1976D2).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFF1976D2), width: 2),
            ),
            child: IconButton(
              icon: Icon(Icons.close, color: Color(0xFF1976D2), size: 20),
              onPressed: () => Navigator.of(context).pop(),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minDim = widget.displaySize.shortestSide;
    final double radius = minDim * 0.04;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop();
        }
      },
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: _buildPreferencesMenu(context),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesMenu(BuildContext context) {
    Widget sectionTitle(String title) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
        );

    Widget makeRuleCheckboxRow(String title, RuleVariation v) {
      return CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        visualDensity: VisualDensity.compact,
        title:
            Text(title, style: TextStyle(fontSize: 13, color: Colors.black87)),
        onChanged: (bool? checked) {
          setState(() {
            widget.game.rules.setVariationEnabled(v, checked == true);
            widget.preferences
                .setBool(prefsKeyForVariation(v), checked == true);
          });
        },
        value: widget.game.rules.isVariationEnabled(v),
        activeColor: Color(0xFF1976D2),
        checkColor: Colors.white,
      );
    }

    Widget makeAiSpeedRow() {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Cat slap speed',
                style: TextStyle(fontSize: 13, color: Colors.black87)),
            DropdownButton<AISlapSpeed>(
              value: widget.aiSlapSpeed,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              underline: SizedBox(),
              onChanged: (AISlapSpeed? value) {
                if (value != null) {
                  setState(() {
                    widget.onAiSlapSpeedChanged(value);
                    widget.preferences
                        .setString(aiSlapSpeedPrefsKey, value.toString());
                  });
                }
              },
              items: [
                DropdownMenuItem(
                    value: AISlapSpeed.slow,
                    child: Text('Slow',
                        style: TextStyle(fontSize: 12, color: Colors.black87))),
                DropdownMenuItem(
                    value: AISlapSpeed.medium,
                    child: Text('Medium',
                        style: TextStyle(fontSize: 12, color: Colors.black87))),
                DropdownMenuItem(
                    value: AISlapSpeed.fast,
                    child: Text('Fast',
                        style: TextStyle(fontSize: 12, color: Colors.black87))),
              ],
            ),
          ],
        ),
      );
    }

    Widget makeSlapPenaltyRow() {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wrong slap penalty',
                style: TextStyle(fontSize: 13, color: Colors.black87)),
            SizedBox(height: 8),
            DropdownButton<BadSlapPenaltyType>(
              value: widget.game.rules.badSlapPenalty,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              isExpanded: true,
              underline: SizedBox(),
              onChanged: (BadSlapPenaltyType? p) {
                if (p != null) {
                  setState(() {
                    widget.game.rules.badSlapPenalty = p;
                    widget.preferences
                        .setString(badSlapPenaltyPrefsKey, p.toString());
                  });
                }
              },
              items: [
                DropdownMenuItem(
                    value: BadSlapPenaltyType.none,
                    child: Text('None',
                        style: TextStyle(fontSize: 12, color: Colors.black87))),
                DropdownMenuItem(
                    value: BadSlapPenaltyType.penalty_card,
                    child: Text('Penalty card',
                        style: TextStyle(fontSize: 12, color: Colors.black87))),
                DropdownMenuItem(
                    value: BadSlapPenaltyType.slap_timeout,
                    child: Text("Can't slap for next 5 cards",
                        style: TextStyle(fontSize: 11, color: Colors.black87))),
                DropdownMenuItem(
                    value: BadSlapPenaltyType.opponent_wins_pile,
                    child: Text('Opponent wins pile',
                        style: TextStyle(fontSize: 12, color: Colors.black87))),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader('Preferences'),

        // Scrollable content with white background
        Flexible(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Scrollbar(
              thumbVisibility: true,
              radius: Radius.circular(8),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // General settings
                      sectionTitle('AUDIO'),
                      CheckboxListTile(
                        dense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        visualDensity: VisualDensity.compact,
                        title: Text("Enable sound effects",
                            style:
                                TextStyle(fontSize: 13, color: Colors.black87)),
                        value: widget.soundPlayer.enabled,
                        activeColor: Color(0xFF1976D2),
                        checkColor: Colors.white,
                        onChanged: (bool? checked) {
                          setState(() {
                            widget.onSoundEnabledChanged(checked == true);
                          });
                        },
                      ),
                      CheckboxListTile(
                        dense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        visualDensity: VisualDensity.compact,
                        title: Text("Enable background music",
                            style:
                                TextStyle(fontSize: 13, color: Colors.black87)),
                        value: widget.soundPlayer.musicEnabled,
                        activeColor: Color(0xFF1976D2),
                        checkColor: Colors.white,
                        onChanged: (bool? checked) {
                          setState(() {
                            widget.onMusicEnabledChanged(checked == true);
                          });
                        },
                      ),
                      SizedBox(height: 8),

                      sectionTitle('AI DIFFICULTY'),
                      makeAiSpeedRow(),

                      Divider(color: Colors.black12, height: 24),

                      // Game rules
                      sectionTitle('GAME RULES'),
                      makeRuleCheckboxRow(
                          'Tens are stoppers', RuleVariation.ten_is_stopper),

                      sectionTitle('SLAP CONDITIONS'),
                      makeRuleCheckboxRow(
                          'Sandwiches', RuleVariation.slap_on_sandwich),
                      makeRuleCheckboxRow(
                          'Run of 3', RuleVariation.slap_on_run_of_3),
                      makeRuleCheckboxRow('4 of same suit',
                          RuleVariation.slap_on_same_suit_of_4),
                      makeRuleCheckboxRow(
                          'Adds to 10', RuleVariation.slap_on_add_to_10),
                      makeRuleCheckboxRow(
                          'Marriages', RuleVariation.slap_on_marriage),
                      makeRuleCheckboxRow(
                          'Divorces', RuleVariation.slap_on_divorce),

                      Divider(color: Colors.black12, height: 24),

                      sectionTitle('PENALTIES'),
                      makeSlapPenaltyRow(),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
