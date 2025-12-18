import 'dart:ui';
import 'package:flutter/material.dart';

/// A modern glass-effect bottom sheet for the main menu.
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
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    barrierColor: Colors.transparent,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final minDim = displaySize.shortestSide;
      final double radius = minDim * 0.04;
      final buttonPadding =
          EdgeInsets.symmetric(vertical: 12.0, horizontal: 18.0);

      Widget bigButton(String text, VoidCallback cb) => Padding(
            padding: EdgeInsets.symmetric(vertical: 6.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: buttonPadding,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 6,
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                cb();
              },
              child: SizedBox(
                  width: double.infinity, child: Center(child: Text(text))),
            ),
          );

      Widget smallButton(String text, VoidCallback cb) => Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 2,
                textStyle: TextStyle(fontSize: 15),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                cb();
              },
              child: Text(text),
            ),
          );

      return WillPopScope(
          onWillPop: () async => false,
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
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Slap Cards',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF7A0B0B),
                                  fontFamily: 'Georgia')),
                        ),

                        // Emphasized game buttons
                        bigButton('Play vs CPU', onOnePlayer),
                        bigButton('2 local player', onTwoPlayer),
                        // bigButton('Watch the cats', onWatchAi),
                        // Removed the large button for 'Watch the cats'
                        SizedBox(height: 8),

                        // Less emphasized secondary actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            smallButton('Preferences...', onPreferences),
                            // watch the cats moved to small button group
                            SizedBox(width: 8),
                            smallButton('Watch the cats', onWatchAi),
                            SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                // call with the outer context so the about dialog uses the app bundle
                                onAbout(context);
                              },
                              child: Text('About...'),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ));
    },
  );
}
