import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'soundeffects.dart';
import 'game.dart';
import 'types.dart';
import 'preferences_sheet.dart';
import 'rules_sheet.dart';

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
  void _openPreferences() async {
    await showPreferencesBottomSheet(
      context,
      widget.displaySize,
      preferences: widget.preferences,
      game: widget.game,
      aiSlapSpeed: widget.aiSlapSpeed,
      onAiSlapSpeedChanged: widget.onAiSlapSpeedChanged,
      onSoundEnabledChanged: widget.onSoundEnabledChanged,
      onMusicEnabledChanged: widget.onMusicEnabledChanged,
      soundPlayer: widget.soundPlayer,
      onClose: () {},
    );
  }

  void _openRules() async {
    await showRulesBottomSheet(
      context,
      widget.displaySize,
      onClose: () {},
    );
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
                child: _buildMainMenu(context),
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
        SizedBox(height: 10),

        // Secondary actions
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child:
                  smallButton('Preferences', Icons.settings, _openPreferences),
            ),
            SizedBox(width: 8),
            Expanded(
              child: smallButton('Rules', Icons.menu_book, _openRules),
            ),
          ],
        ),
        SizedBox(height: 8),
      ],
    );
  }
}
