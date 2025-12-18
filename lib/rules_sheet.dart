import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows the game rules bottom sheet. When closed, calls onClose callback.
Future<void> showRulesBottomSheet(
  BuildContext context,
  Size displaySize, {
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
      return _RulesBottomSheetContent(
        displaySize: displaySize,
        onClose: onClose,
      );
    },
  ).then((_) => onClose());
}

class _RulesBottomSheetContent extends StatelessWidget {
  final Size displaySize;
  final VoidCallback onClose;

  const _RulesBottomSheetContent({
    required this.displaySize,
    required this.onClose,
  });

  Widget _buildSectionHeader(BuildContext context, String title) {
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
    final minDim = displaySize.shortestSide;
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader(context, 'Game Rules'),

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
                                    p: TextStyle(
                                        fontSize: 13, color: Colors.black87),
                                    listBullet: TextStyle(
                                        fontSize: 13, color: Colors.black87),
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
                                return Center(
                                    child: CircularProgressIndicator());
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
