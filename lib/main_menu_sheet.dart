import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'soundeffects.dart';
import 'game.dart';
import 'types.dart';

/// A modern glass-effect bottom sheet for the main menu with integrated preferences.
/// Call `showMainMenuBottomSheet` to present it. Buttons call the provided callbacks
/// after closing the sheet.
Future<void> showMainMenuBottomSheet(
  BuildContext context,
  Size displaySize, {
  required VoidCallback onOnePlayer,
  required VoidCallback onTwoPlayer,
  required VoidCallback onWatchAi,
  required VoidCallback onPreferences,
  required void Function(BuildContext) onAbout,
  required SharedPreferences preferences,
  required Game game,
  required AISlapSpeed aiSlapSpeed,
  required Function(AISlapSpeed) onAiSlapSpeedChanged,
  required Function(bool) onSoundEnabledChanged,
  required Function(bool) onMusicEnabledChanged,
  required SoundEffectPlayer soundPlayer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    barrierColor: Colors.transparent,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _MainMenuBottomSheetContent(
        displaySize: displaySize,
        onOnePlayer: onOnePlayer,
        onTwoPlayer: onTwoPlayer,
        onWatchAi: onWatchAi,
        onPreferences: onPreferences,
        onAbout: onAbout,
        preferences: preferences,
        game: game,
        aiSlapSpeed: aiSlapSpeed,
        onAiSlapSpeedChanged: onAiSlapSpeedChanged,
        onSoundEnabledChanged: onSoundEnabledChanged,
        onMusicEnabledChanged: onMusicEnabledChanged,
        soundPlayer: soundPlayer,
        parentContext: context,
      );
    },
  );
}

enum _MenuView { main, preferences, rules }

class _MainMenuBottomSheetContent extends StatefulWidget {
  final Size displaySize;
  final VoidCallback onOnePlayer;
  final VoidCallback onTwoPlayer;
  final VoidCallback onWatchAi;
  final VoidCallback onPreferences;
  final void Function(BuildContext) onAbout;
  final SharedPreferences preferences;
  final Game game;
  final AISlapSpeed aiSlapSpeed;
  final Function(AISlapSpeed) onAiSlapSpeedChanged;
  final Function(bool) onSoundEnabledChanged;
  final Function(bool) onMusicEnabledChanged;
  final SoundEffectPlayer soundPlayer;
  final BuildContext parentContext;

  const _MainMenuBottomSheetContent({
    required this.displaySize,
    required this.onOnePlayer,
    required this.onTwoPlayer,
    required this.onWatchAi,
    required this.onPreferences,
    required this.onAbout,
    required this.preferences,
    required this.game,
    required this.aiSlapSpeed,
    required this.onAiSlapSpeedChanged,
    required this.onSoundEnabledChanged,
    required this.onMusicEnabledChanged,
    required this.soundPlayer,
    required this.parentContext,
  });

  @override
  State<_MainMenuBottomSheetContent> createState() =>
      _MainMenuBottomSheetContentState();
}

class _MainMenuBottomSheetContentState
    extends State<_MainMenuBottomSheetContent> {
  _MenuView _currentView = _MenuView.main;

  void _navigateToPreferences() {
    setState(() => _currentView = _MenuView.preferences);
  }

  void _navigateToRules() {
    setState(() => _currentView = _MenuView.rules);
  }

  void _navigateToMain() {
    setState(() => _currentView = _MenuView.main);
  }

  @override
  Widget build(BuildContext context) {
    final minDim = widget.displaySize.shortestSide;
    final double radius = minDim * 0.04;

    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(radius),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: _currentView == _MenuView.main
                    ? _buildMainMenu(context)
                    : _currentView == _MenuView.preferences
                        ? _buildPreferencesMenu(context)
                        : _buildRulesMenu(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainMenu(BuildContext context) {
    Widget bigButton(String text, IconData icon, VoidCallback cb,
        Color backgroundColor, Color foregroundColor) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 6.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [backgroundColor, backgroundColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                Navigator.of(context).pop();
                cb();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 26, color: foregroundColor),
                    SizedBox(width: 12),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: foregroundColor,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget smallButton(String text, IconData icon, VoidCallback cb) =>
        FilledButton(
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            foregroundColor: Colors.black87,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          onPressed: cb,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              SizedBox(width: 6),
              Text(text),
            ],
          ),
        );

    Widget iconButton(IconData icon, VoidCallback cb) => Material(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              cb();
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top bar with Watch the cats icon
        Row(
          children: [
            iconButton(Icons.visibility, widget.onWatchAi),
            Spacer(),
          ],
        ),
        SizedBox(height: 12),

        // Logo
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Image.asset(
            'assets/logo/slapcards-write.png',
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 24),

        // Main game buttons
        bigButton('Play vs CPU', Icons.pets, widget.onOnePlayer,
            Color(0xFF1976D2), Colors.white),
        bigButton('2 Local Players', Icons.people, widget.onTwoPlayer,
            Color.fromARGB(255, 220, 150, 10), Colors.white),
        SizedBox(height: 16),

        // Secondary actions
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: smallButton(
                  'Preferences', Icons.settings, _navigateToPreferences),
            ),
            SizedBox(width: 8),
            Expanded(
              child: smallButton('Rules', Icons.menu_book, _navigateToRules),
            ),
          ],
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPreferencesMenu(BuildContext context) {
    final titleFontSize = 18.0;

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
        // Header with back button
        Padding(
          padding: EdgeInsets.only(left: 4, right: 16, top: 4, bottom: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: _navigateToMain,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                'Preferences',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

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

        // Back button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            onPressed: _navigateToMain,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_rounded, size: 18),
                SizedBox(width: 8),
                Text('Done'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRulesMenu(BuildContext context) {
    final titleFontSize = 18.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with back button
        Padding(
          padding: EdgeInsets.only(left: 4, right: 16, top: 4, bottom: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: _navigateToMain,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                'Game Rules',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

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
                  padding: EdgeInsets.all(16),
                  child: FutureBuilder<String>(
                    future: DefaultAssetBundle.of(context)
                        .loadString('assets/doc/about.md'),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        // Remove email contact line
                        String content = snapshot.data!;
                        content = content.replaceFirst(
                            RegExp(r'^Comments or bug reports:.*\n\n?',
                                multiLine: true),
                            '');

                        return MarkdownBody(
                          data: content,
                          styleSheet: MarkdownStyleSheet(
                            h2: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                            p: TextStyle(fontSize: 13, color: Colors.black87),
                            listBullet:
                                TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                          onTapLink: (text, href, title) =>
                              launch(href ?? ''),
                          listItemCrossAxisAlignment:
                              MarkdownListItemCrossAxisAlignment.start,
                        );
                      } else if (snapshot.hasError) {
                        return Text('Error loading rules',
                            style: TextStyle(color: Colors.red));
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ),

        // Back button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            onPressed: _navigateToMain,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_rounded, size: 18),
                SizedBox(width: 8),
                Text('Done'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
