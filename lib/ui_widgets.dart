import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'game.dart';

const cardAspectRatio = 521.0 / 726;

class PlayCardButton extends StatelessWidget {
  final Game game;
  final int playerIndex;
  final VoidCallback? onPressed;
  final Size displaySize;

  const PlayCardButton({
    Key? key,
    required this.game,
    required this.playerIndex,
    required this.onPressed,
    required this.displaySize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enabled = game.canPlayCard(playerIndex);
    final cardsLeft = game.playerCards[playerIndex].length;

    return Transform.rotate(
      angle: (playerIndex == 1) ? pi : 0,
      child: Padding(
        padding: EdgeInsets.all(0.025 * displaySize.height),
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                enabled ? Colors.blue.shade700 : Colors.grey.shade400,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: enabled ? 4 : 1,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.style,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Play card',
                    style: TextStyle(
                      fontSize:
                          Theme.of(context).textTheme.headlineMedium!.fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$cardsLeft',
                      style: TextStyle(
                        fontSize:
                            Theme.of(context).textTheme.bodyLarge!.fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: ' / 52',
                      style: TextStyle(
                        fontSize:
                            Theme.of(context).textTheme.bodyMedium!.fontSize,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardImageWidget extends StatelessWidget {
  final String imagePath;

  const CardImageWidget({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isSvg = imagePath.endsWith('.svg');

    return LayoutBuilder(builder: (context, constraints) {
      double width = constraints.maxWidth;
      double height = constraints.maxHeight;
      double viewAspectRatio = width / height;

      final cardRect = (() {
        if (viewAspectRatio > cardAspectRatio) {
          // Full height, centered width.
          double cardWidth = height * cardAspectRatio;
          return Rect.fromLTWH(width / 2 - cardWidth / 2, 0, cardWidth, height);
        } else {
          // Full width, centered height.
          double cardHeight = width / cardAspectRatio;
          return Rect.fromLTWH(
              0, height / 2 - cardHeight / 2, width, cardHeight);
        }
      })();

      // Very rounded corners with subtle gray border (increased to 0.15)
      final borderRadius = BorderRadius.circular(cardRect.width * 0.15);

      return Stack(children: [
        Positioned.fromRect(
          rect: cardRect,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: isSvg
                ? SvgPicture.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  )
                : Image(
                    image: AssetImage(imagePath),
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
          ),
        ),
        Positioned.fromRect(
          rect: cardRect,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade400,
                width: 1.0,
              ),
              borderRadius: borderRadius,
            ),
          ),
        ),
      ]);
    });
  }
}

class NoSlapIndicator extends StatelessWidget {
  final int playerIndex;
  final int numTimeoutCards;
  final Size displaySize;
  final int catImageNumber;

  const NoSlapIndicator({
    Key? key,
    required this.playerIndex,
    required this.numTimeoutCards,
    required this.displaySize,
    required this.catImageNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (numTimeoutCards <= 0) {
      return SizedBox.shrink();
    }

    final minDim = min(displaySize.width, displaySize.height);
    final size = min(minDim * 0.2, 100.0);
    final padding = 10.0;

    return Positioned(
      left: playerIndex == 0 ? padding : null,
      bottom: playerIndex == 0 ? padding : null,
      right: playerIndex == 0 ? null : padding,
      top: playerIndex == 0 ? null : padding,
      child: Transform.rotate(
        angle: playerIndex == 1 ? pi : 0,
        child: Stack(
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Image(
                image: AssetImage('assets/cats/paw$catImageNumber.png'),
              ),
            ),
            SizedBox(
              width: size,
              height: size,
              child: Image(image: AssetImage('assets/misc/no.png')),
            ),
            Padding(
              padding: EdgeInsets.only(left: size * 0.55, top: size * 0.55),
              child: SizedBox(
                width: size * 0.45,
                height: size * 0.45,
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: CircleBorder(),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {},
                  child: Text(
                    numTimeoutCards.toString(),
                    style: TextStyle(fontSize: size * 0.24, height: 0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
