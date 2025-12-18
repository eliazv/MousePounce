import 'package:flutter/material.dart';

/// Glass-style bottom sheet for paused menu. Returns when dismissed.
Future<void> showPausedMenuBottomSheet(BuildContext context, Size displaySize,
    {required VoidCallback onContinue, required VoidCallback onEnd}) {
  final minDim = displaySize.shortestSide;
  final double radius = minDim * 0.04;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // dim background so modal stands out
    barrierColor: Colors.black54,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 6)),
                ],
              ),
              padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Text('Game Paused',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7A0B0B))),
                  ),
                  SizedBox(height: 12),

                  // Continue (primary)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.play_arrow, color: Colors.white),
                      label: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Continue',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF7A0B0B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 6,
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onContinue();
                      },
                    ),
                  ),
                  SizedBox(height: 10),

                  // End Game (secondary)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.stop, color: Color(0xFF7A0B0B)),
                      label: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('End Game',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7A0B0B))),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Color(0xFF7A0B0B), width: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onEnd();
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
