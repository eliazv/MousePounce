import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game.dart';
import 'types.dart';
import 'soundeffects.dart';
import 'animation_helpers.dart';

enum AIMode { human_vs_human, human_vs_ai, ai_vs_ai }

enum DialogMode {
  none,
  main_menu,
  preferences,
  game_paused,
  game_over,
  statistics,
  animation_speed_warning,
}

/// Manages the game state including AI behavior, animations, and moods
class GameStateManager extends ChangeNotifier {
  Random rng = Random();
  Game game = Game();
  AnimationMode animationMode = AnimationMode.none;
  AIMode aiMode = AIMode.ai_vs_ai;
  DialogMode dialogMode = DialogMode.none;
  int? pileMovingToPlayer;
  int? badSlapPileWinner;
  PileCard? penaltyCard;
  bool penaltyCardPlayed = false;
  int? aiSlapPlayerIndex;
  int aiSlapCounter = 0;
  late List<int> catImageNumbers;
  List<AIMood> aiMoods = [AIMood.none, AIMood.none];
  AISlapSpeed aiSlapSpeed = AISlapSpeed.medium;
  final numCatImages = 4;
  SoundEffectPlayer soundPlayer = SoundEffectPlayer();
  bool menuButtonVisible = false;
  bool menuOpen = false;

  final moodWeights = {
    Rank.ace: 2,
    Rank.king: 4,
    Rank.queen: 6,
    Rank.jack: 12,
  };

  GameStateManager() {
    game = Game(rng: rng);
    catImageNumbers = _randomCatImageNumbers();
    penaltyCard = null;
    soundPlayer.init();
  }

  List<int> _randomCatImageNumbers() {
    int c1 = rng.nextInt(numCatImages);
    int c2 = (c1 + 1 + rng.nextInt(numCatImages - 1)) % numCatImages;
    return [c1 + 1, c2 + 1];
  }

  void readPreferencesAndStartGame(SharedPreferences preferences) {
    soundPlayer.enabled = preferences.getBool(soundEnabledPrefsKey) ?? true;

    for (var v in RuleVariation.values) {
      bool enabled = preferences.getBool(prefsKeyForVariation(v)) ?? false;
      game.rules.setVariationEnabled(v, enabled);
    }

    final speedStr = preferences.getString(aiSlapSpeedPrefsKey) ?? '';
    aiSlapSpeed = AISlapSpeed.values.firstWhere((s) => s.toString() == speedStr,
        orElse: () => AISlapSpeed.medium);

    final penaltyStr = preferences.getString(badSlapPenaltyPrefsKey) ?? '';
    game.rules.badSlapPenalty = BadSlapPenaltyType.values.firstWhere(
        (s) => s.toString() == penaltyStr,
        orElse: () => BadSlapPenaltyType.none);
  }

  bool shouldAiPlayCard() {
    if (game.gameWinner() != null) {
      return false;
    }
    if (animationMode != AnimationMode.none) {
      return false;
    }
    return aiMode == AIMode.ai_vs_ai ||
        (aiMode == AIMode.human_vs_ai && game.currentPlayerIndex == 1);
  }

  int aiSlapDelayMillis() {
    int baseDelay = 300 + (500 * rng.nextDouble()).toInt();
    switch (aiSlapSpeed) {
      case AISlapSpeed.medium:
        return baseDelay;
      case AISlapSpeed.fast:
        return (baseDelay * 0.6).toInt();
      case AISlapSpeed.slow:
        return baseDelay * 2;
    }
  }

  bool aiHasMoodForPile(final List<PileCard> pileCards) {
    int total = 0;
    for (PileCard pc in pileCards) {
      int cval = moodWeights.containsKey(pc.card.rank)
          ? moodWeights[pc.card.rank]!
          : 1;
      total += cval;
    }
    return total > 16;
  }

  void setAiMoods(final List<AIMood> moods) {
    aiMoods = moods;
    notifyListeners();
  }

  void updateAiMoodsForPile(final List<PileCard> pileCards, final int pileWinner) {
    if (aiHasMoodForPile(pileCards)) {
      var moods = pileWinner == 0
          ? [AIMood.happy, AIMood.angry]
          : [AIMood.angry, AIMood.happy];
      setAiMoods(moods);
      _playSoundForMoods(moods);
    }
  }

  void updateAiMoodsForGameWinner(int winner) {
    var moods = winner == 0
        ? [AIMood.very_happy, AIMood.angry]
        : [AIMood.angry, AIMood.very_happy];
    setAiMoods(moods);
    _playSoundForMoods(moods);
  }

  void _playSoundForMoods(final List<AIMood> moods) {
    if (aiMode != AIMode.human_vs_ai) {
      return;
    }
    switch (moods[1]) {
      case AIMood.angry:
        soundPlayer.playMadSound();
        break;
      case AIMood.happy:
      case AIMood.very_happy:
        soundPlayer.playHappySound();
        break;
      default:
        break;
    }
  }

  bool isGameActive() {
    try {
      return game.playerCards.isNotEmpty &&
          (game.playerCards[0].isNotEmpty || game.playerCards[1].isNotEmpty);
    } catch (e) {
      return false;
    }
  }

  void startOnePlayerGame() {
    aiMode = AIMode.human_vs_ai;
    dialogMode = DialogMode.none;
    menuButtonVisible = false;
    animationMode = AnimationMode.none;
    catImageNumbers = _randomCatImageNumbers();
    aiSlapCounter++;
    game.startGame();
    notifyListeners();
  }

  void startTwoPlayerGame() {
    aiMode = AIMode.human_vs_human;
    dialogMode = DialogMode.none;
    menuButtonVisible = false;
    animationMode = AnimationMode.none;
    aiSlapCounter++;
    game.startGame();
    notifyListeners();
  }

  void startNewGame() {
    dialogMode = DialogMode.none;
    menuButtonVisible = false;
    animationMode = AnimationMode.none;
    aiSlapCounter++;
    game.startGame();
    notifyListeners();
  }

  void continueGame() {
    dialogMode = DialogMode.none;
    menuButtonVisible = false;
    notifyListeners();
  }

  void endGame() {
    dialogMode = DialogMode.none;
    aiMode = AIMode.ai_vs_ai;
    menuButtonVisible = false;
    animationMode = AnimationMode.none;
    aiSlapCounter++;
    game.startGame();
    notifyListeners();
  }

  void watchAiGame() {
    dialogMode = DialogMode.none;
    menuButtonVisible = true;
    if (aiMode != AIMode.ai_vs_ai) {
      aiMode = AIMode.ai_vs_ai;
      game.startGame();
    }
    notifyListeners();
  }
}
