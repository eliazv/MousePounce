import 'dart:math';
import 'package:flutter/material.dart';
import 'game.dart';
import 'ui_widgets.dart';

const illegalSlapAnimationDuration = Duration(milliseconds: 600);
const moodDuration = Duration(milliseconds: 5000);
const moodFadeMillis = 500;

enum AnimationMode {
  none,
  play_card_back,
  play_card_front,
  ai_slap,
  waiting_to_move_pile,
  pile_to_winner,
  illegal_slap,
}

enum AIMood { none, happy, very_happy, angry }

final aiMoodImages = {
  AIMood.happy: 'bubble_happy.png',
  AIMood.very_happy: 'bubble_grin.png',
  AIMood.angry: 'bubble_mad.png',
};

class PileCardWidget extends StatelessWidget {
  final PileCard pileCard;
  final Size displaySize;
  final double rotationFrac;
  final Function(Offset, double)? onTapDown;
  final String cardImagePath;

  const PileCardWidget({
    Key? key,
    required this.pileCard,
    required this.displaySize,
    this.rotationFrac = 1.0,
    this.onTapDown,
    required this.cardImagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final minDim = min(displaySize.width, displaySize.height);
    final maxOffset = minDim * 0.1;

    return Container(
      height: double.infinity,
      width: double.infinity,
      child: Transform.translate(
        offset: Offset(
          pileCard.xOffset * maxOffset,
          pileCard.yOffset * maxOffset,
        ),
        child: Transform.rotate(
          angle: pileCard.rotation * rotationFrac * pi / 12,
          child: FractionallySizedBox(
            alignment: Alignment.center,
            heightFactor: 0.7,
            widthFactor: 0.7,
            child: GestureDetector(
              onTapDown: onTapDown != null
                  ? (TapDownDetails tap) {
                      onTapDown!(tap.globalPosition, displaySize.height);
                    }
                  : null,
              child: CardImageWidget(imagePath: cardImagePath),
            ),
          ),
        ),
      ),
    );
  }
}

class AIPlayerWidget extends StatelessWidget {
  final int playerIndex;
  final AIMood mood;
  final int catImageNumber;
  final VoidCallback? onMoodEnd;

  const AIPlayerWidget({
    Key? key,
    required this.playerIndex,
    required this.mood,
    required this.catImageNumber,
    this.onMoodEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final moodImage = aiMoodImages[mood];

    return Transform.rotate(
      angle: playerIndex == 1 ? 0 : pi,
      child: Stack(
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, 10),
              child: Image(
                image: AssetImage('assets/cats/cat$catImageNumber.png'),
                fit: BoxFit.fitHeight,
                alignment: Alignment.center,
              ),
            ),
          ),
          if (moodImage != null)
            Positioned.fill(
              top: 5,
              bottom: 40,
              child: Transform.translate(
                offset: Offset(110, 0),
                child: TweenAnimationBuilder(
                  tween: Tween(
                    begin: 0.0,
                    end: moodDuration.inMilliseconds.toDouble(),
                  ),
                  duration: moodDuration,
                  onEnd: onMoodEnd,
                  child: Image(
                    image: AssetImage('assets/cats/$moodImage'),
                    fit: BoxFit.fitHeight,
                    alignment: Alignment.center,
                  ),
                  builder: (BuildContext context, double animMillis, Widget? child) {
                    double op = 1.0;
                    if (animMillis < moodFadeMillis) {
                      op = animMillis / moodFadeMillis;
                    } else if (animMillis > moodDuration.inMilliseconds - moodFadeMillis) {
                      op = (moodDuration.inMilliseconds - animMillis) / moodFadeMillis;
                    }
                    return Opacity(opacity: op, child: child);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PlayCardAnimation extends StatelessWidget {
  final PileCard lastPileCard;
  final Size displaySize;
  final VoidCallback onEnd;
  final List<Widget> previousCards;
  final String cardImagePath;

  const PlayCardAnimation({
    Key? key,
    required this.lastPileCard,
    required this.displaySize,
    required this.onEnd,
    required this.previousCards,
    required this.cardImagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ...previousCards,
        TweenAnimationBuilder(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 200),
          onEnd: onEnd,
          builder: (BuildContext context, double animValue, Widget? child) {
            double startYOff = displaySize.height / 2 * (lastPileCard.playedBy == 0 ? 1 : -1);
            return Transform.translate(
              offset: Offset(0, startYOff * (1 - animValue)),
              child: PileCardWidget(
                pileCard: lastPileCard,
                displaySize: displaySize,
                rotationFrac: animValue,
                cardImagePath: cardImagePath,
              ),
            );
          },
        ),
      ],
    );
  }
}

class PileToWinnerAnimation extends StatelessWidget {
  final int pileMovingToPlayer;
  final Size displaySize;
  final VoidCallback onEnd;
  final Widget pileStack;

  const PileToWinnerAnimation({
    Key? key,
    required this.pileMovingToPlayer,
    required this.displaySize,
    required this.onEnd,
    required this.pileStack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double endYOff = displaySize.height * 0.75 * (pileMovingToPlayer == 0 ? 1 : -1);

    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300),
      onEnd: onEnd,
      child: pileStack,
      builder: (BuildContext context, double animValue, Widget? child) {
        return Transform.translate(
          offset: Offset(0, endYOff * animValue),
          child: child,
        );
      },
    );
  }
}

class IllegalSlapAnimation extends StatelessWidget {
  final PileCard? penaltyCard;
  final Size displaySize;
  final List<Widget> pileWidgets;
  final String? penaltyCardImagePath;

  const IllegalSlapAnimation({
    Key? key,
    required this.penaltyCard,
    required this.displaySize,
    required this.pileWidgets,
    this.penaltyCardImagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (penaltyCard != null && penaltyCardImagePath != null)
          TweenAnimationBuilder(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: illegalSlapAnimationDuration,
            builder: (BuildContext context, double animValue, Widget? child) {
              double startYOff = displaySize.height / 2 * (penaltyCard!.playedBy == 0 ? 1 : -1);
              return Transform.translate(
                offset: Offset(0, startYOff * (1 - animValue)),
                child: PileCardWidget(
                  pileCard: penaltyCard!,
                  displaySize: displaySize,
                  rotationFrac: animValue,
                  cardImagePath: penaltyCardImagePath!,
                ),
              );
            },
          ),
        Opacity(
          opacity: penaltyCard != null ? 0.25 : 1.0,
          child: Stack(children: pileWidgets),
        ),
        TweenAnimationBuilder(
          tween: Tween(begin: 2.0, end: 0.0),
          duration: illegalSlapAnimationDuration,
          child: Center(
            child: Image(
              image: AssetImage('assets/misc/no.png'),
              alignment: Alignment.center,
            ),
          ),
          builder: (BuildContext context, double animValue, Widget? child) {
            return Opacity(
              opacity: min(animValue, 1),
              child: child,
            );
          },
        ),
      ],
    );
  }
}
