import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:slapcards/soundeffects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'game.dart';
import 'main_menu_sheet.dart';
import 'paused_menu_sheet.dart';
import 'types.dart';
import 'ui_widgets.dart';
import 'animation_helpers.dart';
import 'haptic_feedback_manager.dart';
import 'background_widgets.dart';

const appTitle = "Egyptian Mouse Pounce";
const appVersion = "1.4.0";
const appLegalese = "© 2025";

void main() {
  runApp(MyApp());
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

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

final dialogBackgroundColor = Color.fromARGB(0xd0, 0xd8, 0xd8, 0xd8);
const dialogTableBackgroundColor = Color.fromARGB(0x80, 0xc0, 0xc0, 0xc0);

class _MyHomePageState extends State<MyHomePage> {
  Random rng = Random();
  late final SharedPreferences preferences;
  Game game = Game();
  late List<String> playerBackgrounds;
  AnimationMode animationMode = AnimationMode.none;
  AIMode aiMode = AIMode.ai_vs_ai;
  DialogMode dialogMode = DialogMode.none;
  int? pileMovingToPlayer;
  int? badSlapPileWinner;
  PileCard? penaltyCard;
  bool penaltyCardPlayed = false;
  int? aiSlapPlayerIndex;
  int aiSlapCounter =
      0; // Used to check if a previously scheduled AI slap is still valid.
  late List<int> catImageNumbers;
  List<AIMood> aiMoods = [AIMood.none, AIMood.none];
  AISlapSpeed aiSlapSpeed = AISlapSpeed.medium;
  final numCatImages = 4;
  final List<String> _backgroundOptions = [
    'assets/background/bedroom.jpg',
    'assets/background/night-bedroom.jpg',
  ];
  SoundEffectPlayer soundPlayer = SoundEffectPlayer();
  bool menuButtonVisible =
      false; // show FAB only when sheet closed via 'Watch the cats'
  bool menuOpen = false;

  @override
  void initState() {
    super.initState();
    game = Game(rng: rng);
    catImageNumbers = _randomCatImageNumbers();
    playerBackgrounds = _randomPlayerBackgrounds(catImageNumbers.length);
    penaltyCard = null;
    soundPlayer.init();
    _readPreferencesAndStartGame();
    // Show the main menu as a bottom sheet on first frame if in AI-vs-AI mode.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (aiMode == AIMode.ai_vs_ai) {
        final fullDisplaySize = MediaQuery.sizeOf(context);
        final displayPadding = MediaQuery.paddingOf(context);
        final displaySize = Size(
            fullDisplaySize.width - displayPadding.left - displayPadding.right,
            fullDisplaySize.height -
                displayPadding.top -
                displayPadding.bottom);
        _showMenu(context, displaySize);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _preloadCardImages();
  }

  void _readPreferencesAndStartGame() async {
    this.preferences = await SharedPreferences.getInstance();
    soundPlayer.enabled = preferences.getBool(soundEnabledPrefsKey) ?? true;
    soundPlayer.musicEnabled =
        preferences.getBool(musicEnabledPrefsKey) ?? true;
    soundPlayer.startBackgroundMusic();

    for (var v in RuleVariation.values) {
      bool enabled = this.preferences.getBool(prefsKeyForVariation(v)) ?? false;
      game.rules.setVariationEnabled(v, enabled);
    }

    final speedStr = this.preferences.getString(aiSlapSpeedPrefsKey) ?? '';
    aiSlapSpeed = AISlapSpeed.values.firstWhere((s) => s.toString() == speedStr,
        orElse: () => AISlapSpeed.medium);

    final penaltyStr = this.preferences.getString(badSlapPenaltyPrefsKey) ?? '';
    game.rules.badSlapPenalty = BadSlapPenaltyType.values.firstWhere(
        (s) => s.toString() == penaltyStr,
        orElse: () => BadSlapPenaltyType.none);

    _scheduleAiPlayIfNeeded();

    runAnimationTimingTestIfNeeded();
  }

  List<int> _randomCatImageNumbers() {
    int c1 = rng.nextInt(numCatImages);
    int c2 = (c1 + 1 + rng.nextInt(numCatImages - 1)) % numCatImages;
    return [c1 + 1, c2 + 1];
  }

  List<String> _randomPlayerBackgrounds(int count) {
    return List.generate(count,
        (_) => _backgroundOptions[rng.nextInt(_backgroundOptions.length)]);
  }

  String _imagePathForCard(final PlayingCard card) {
    return card.svgPath(); // Use SVG from assets/faces
  }

  void _preloadCardImages() async {
    // Preload all PNG images (cats, icons, backgrounds, etc.)
    final pngAssets = [
      // Cat images
      'assets/cats/cat1.png',
      'assets/cats/cat2.png',
      'assets/cats/cat3.png',
      'assets/cats/cat4.png',
      // Cat paws
      'assets/cats/paw1.png',
      'assets/cats/paw2.png',
      'assets/cats/paw3.png',
      'assets/cats/paw4.png',
      // Mood bubbles
      'assets/cats/bubble_happy.png',
      'assets/cats/bubble_grin.png',
      'assets/cats/bubble_mad.png',
      // Icons and misc
      'assets/icons/cards.png',
      'assets/misc/no.png',
      'assets/logo/slapcards-write.png',
      // Backgrounds
      'assets/background/bedroom.jpg',
      'assets/background/night-bedroom.jpg',
    ];

    // Preload galline and gatti if they exist
    for (int i = 1; i <= 10; i++) {
      pngAssets.add('assets/galline/gallina$i.png');
      pngAssets.add('assets/gatti/gatto$i.png');
    }

    // Special gatti
    pngAssets.add('assets/gatti/gatto-bar.png');

    // Preload all PNG/JPG images
    for (final asset in pngAssets) {
      try {
        await precacheImage(AssetImage(asset), context);
      } catch (e) {
        // Ignore errors for optional assets that might not exist
      }
    }

    // Preload all SVG card faces
    final suits = ['CLUB', 'DIAMOND', 'HEART', 'SPADE'];
    final ranks = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11-JACK',
      '12-QUEEN',
      '13-KING'
    ];

    for (final suit in suits) {
      for (final rank in ranks) {
        final path = 'assets/faces/$suit-$rank.svg';
        try {
          // For SVG files, we need to ensure they're in the asset bundle
          // The actual preloading happens when SvgPicture first renders them
          await DefaultAssetBundle.of(context).load(path);
        } catch (e) {
          // Ignore errors for missing assets
        }
      }
    }
  }

  void _playCard() {
    setState(() {
      game.playCard();
      animationMode = AnimationMode.play_card_back;
      aiSlapCounter++;
      penaltyCard = null;
      penaltyCardPlayed = false;
    });
    // Play card placement sound
    soundPlayer.playPlaceCardSound();
  }

  bool _shouldAiPlayCard() {
    if (game.gameWinner() != null) {
      return false;
    }
    // Don't play if we're in the middle of another animation (e.g. penalty card).
    // _scheduleAiPlayIfNeeded should be called when the animation finishes.
    if (animationMode != AnimationMode.none) {
      return false;
    }
    return aiMode == AIMode.ai_vs_ai ||
        (aiMode == AIMode.human_vs_ai && game.currentPlayerIndex == 1);
  }

  void _scheduleAiPlayIfNeeded() {
    final thisGame = game;
    if (_shouldAiPlayCard()) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (thisGame == game &&
            _shouldAiPlayCard() &&
            badSlapPileWinner == null) {
          _playCard();
        }
      });
    }
  }

  int _aiSlapDelayMillis() {
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

  void _playCardFinished() {
    animationMode = AnimationMode.none;
    if (game.canSlapPile() && aiMode != AIMode.human_vs_human) {
      final delayMillis = _aiSlapDelayMillis();
      aiSlapCounter++;
      final counterSnapshot = aiSlapCounter;
      final aiIndex = aiMode == AIMode.human_vs_ai ? 1 : rng.nextInt(2);
      Future.delayed(Duration(milliseconds: delayMillis), () {
        if (counterSnapshot == aiSlapCounter) {
          setState(() {
            animationMode = AnimationMode.ai_slap;
            pileMovingToPlayer = aiIndex;
            aiSlapPlayerIndex = aiIndex;
            Future.delayed(Duration(milliseconds: 1000), () {
              setState(() => animationMode = AnimationMode.pile_to_winner);
            });
          });
        }
      });
    } else {
      final pileWinner = game.challengeChanceWinner;
      if (pileWinner != null) {
        animationMode = AnimationMode.waiting_to_move_pile;
        Future.delayed(const Duration(milliseconds: 1000), () {
          setState(() {
            if (this.animationMode == AnimationMode.waiting_to_move_pile) {
              this.pileMovingToPlayer = pileWinner;
              this.animationMode = AnimationMode.pile_to_winner;
            }
          });
        });
      } else {
        _scheduleAiPlayIfNeeded();
      }
    }
  }

  final moodWeights = {
    Rank.ace: 2,
    Rank.king: 4,
    Rank.queen: 6,
    Rank.jack: 12,
  };

  // Whether the AI should show a mood after winning or losing a pile, as determined by the number
  // and importance of cards in the pile.
  bool _aiHasMoodForPile(final List<PileCard> pileCards) {
    int total = 0;
    for (PileCard pc in pileCards) {
      int cval = moodWeights.containsKey(pc.card.rank)
          ? moodWeights[pc.card.rank]!
          : 1;
      total += cval;
    }
    return total > 16;
  }

  void _setAiMoods(final List<AIMood> moods) {
    setState(() => aiMoods = moods);
  }

  void _updateAiMoodsForPile(
      final List<PileCard> pileCards, final int pileWinner) {
    if (_aiHasMoodForPile(pileCards)) {
      var moods = pileWinner == 0
          ? [AIMood.happy, AIMood.angry]
          : [AIMood.angry, AIMood.happy];
      _setAiMoods(moods);

      _playSoundForMoods(moods);
    }
  }

  void _updateAiMoodsForGameWinner(int winner) {
    var moods = winner == 0
        ? [AIMood.very_happy, AIMood.angry]
        : [AIMood.angry, AIMood.very_happy];
    _setAiMoods(moods);
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

  void _movePileToWinner() {
    final cardsWon = [...game.pileCards];
    game.movePileToPlayer(pileMovingToPlayer!);

    // Play deck redraw sound and trigger haptic feedback when taking cards
    soundPlayer.playDeckRedrawSound();
    HapticFeedbackManager.triggerCardTakeVibration();

    int? winner = game.gameWinner();
    if (winner != null) {
      _updateAiMoodsForGameWinner(winner);
      // Play win sound
      soundPlayer.playWinSound();
      if (aiMode == AIMode.ai_vs_ai) {
        Future.delayed(const Duration(milliseconds: 2000), () {
          setState(() {
            game.startGame();
            _scheduleAiPlayIfNeeded();
          });
        });
      } else {
        dialogMode = DialogMode.game_over;
      }
    } else {
      _updateAiMoodsForPile(cardsWon, pileMovingToPlayer!);
    }

    animationMode = AnimationMode.none;
    pileMovingToPlayer = null;
    _scheduleAiPlayIfNeeded();
  }

  void _playCardIfPlayerTurn(int pnum) {
    if (animationMode != AnimationMode.none) {
      return;
    }
    if (game.canPlayCard(pnum)) {
      setState(_playCard);
    }
  }

  void _doSlap(Offset globalOffset, double globalHeight) {
    if (animationMode != AnimationMode.none &&
        animationMode != AnimationMode.waiting_to_move_pile) {
      return;
    }
    int pnum = 0;
    if (aiMode == AIMode.human_vs_human) {
      pnum = (globalOffset.dy > globalHeight / 2) ? 0 : 1;
    }
    if (!game.isPlayerAllowedToSlap(pnum)) {
      return;
    }
    if (game.canSlapPile()) {
      setState(() {
        aiSlapCounter++;
        pileMovingToPlayer = pnum;
        animationMode = AnimationMode.pile_to_winner;
      });
    } else {
      _handleIllegalSlap(pnum);
    }
  }

  void _handleIllegalSlap(final int playerIndex) {
    final penalty = this.game.rules.badSlapPenalty;
    setState(() {
      this.animationMode = AnimationMode.illegal_slap;
      switch (penalty) {
        case BadSlapPenaltyType.penalty_card:
          // Only one penalty card per real card?
          if (!penaltyCardPlayed) {
            this.penaltyCard = game.addPenaltyCard(playerIndex);
            this.penaltyCardPlayed = (penaltyCard != null);
          }
          break;
        case BadSlapPenaltyType.slap_timeout:
          this.game.setSlapTimeoutCardsForPlayer(5, playerIndex);
          break;
        case BadSlapPenaltyType.opponent_wins_pile:
          this.badSlapPileWinner = 1 - playerIndex;
          break;
        default:
          break;
      }
    });
    // When the slap animation finishes, move the pile to the winner if there is one.
    Future.delayed(illegalSlapAnimationDuration, () {
      setState(() {
        this.penaltyCard = null;
        if (this.badSlapPileWinner != null) {
          this.pileMovingToPlayer = badSlapPileWinner;
          this.badSlapPileWinner = null;
          this.animationMode = AnimationMode.pile_to_winner;
        } else {
          final cw = this.game.challengeChanceWinner;
          if (cw != null) {
            this.pileMovingToPlayer = cw;
            this.animationMode = AnimationMode.pile_to_winner;
          } else {
            this.animationMode = AnimationMode.none;
          }
        }
      });
      this._scheduleAiPlayIfNeeded();
    });
  }

  Widget _playerStatusWidget(
      final Game game, final int playerIndex, final Size displaySize) {
    return PlayCardButton(
      game: game,
      playerIndex: playerIndex,
      onPressed: () => _playCardIfPlayerTurn(playerIndex),
      displaySize: displaySize,
    );
  }

  Widget _aiPlayerWidget(
      final Game game, final int playerIndex, final Size displaySize) {
    return AIPlayerWidget(
      playerIndex: playerIndex,
      mood: aiMoods[playerIndex],
      catImageNumber: catImageNumbers[playerIndex],
      onMoodEnd: () => setState(() => aiMoods = [AIMood.none, AIMood.none]),
    );
  }

  Widget _pileCardWidget(final PileCard pc, final Size displaySize,
      {final rotationFrac = 1.0}) {
    return PileCardWidget(
      pileCard: pc,
      displaySize: displaySize,
      rotationFrac: rotationFrac,
      onTapDown: dialogMode == DialogMode.none ? _doSlap : null,
      cardImagePath: _imagePathForCard(pc.card),
    );
  }

  List<Widget> _pileCardWidgets(
      Iterable<PileCard> pileCards, final Size displaySize) {
    return pileCards.map((pc) => _pileCardWidget(pc, displaySize)).toList();
  }

  Widget _pileContent(final Game game, final Size displaySize) {
    final pileCardsWithoutLast =
        game.pileCards.sublist(0, max(0, game.pileCards.length - 1));
    final lastPileCard = game.pileCards.isNotEmpty ? game.pileCards.last : null;

    /* // Fixed cards to take screenshots for icon.
    final demoCards = [
      PileCard(PlayingCard(Rank.queen, Suit.diamonds), 0, rng),
      PileCard(PlayingCard(Rank.four, Suit.spades), 0, rng),
      PileCard(PlayingCard(Rank.four, Suit.hearts), 0, rng),
    ];
    demoCards[0].xOffset = -0.7;
    demoCards[0].yOffset = 0.2;
    demoCards[0].rotation = -0.25;
    demoCards[1].xOffset = -0.3;
    demoCards[1].yOffset = -0.2;
    demoCards[1].rotation = 0.15;
    demoCards[2].xOffset = 0.6;
    demoCards[2].yOffset = 0.0;
    demoCards[2].rotation = 0.0;
    */

    switch (animationMode) {
      case AnimationMode.none:
      case AnimationMode.waiting_to_move_pile:
        return Stack(children: _pileCardWidgets(game.pileCards, displaySize));

      case AnimationMode.ai_slap:
        return Stack(children: [
          ..._pileCardWidgets(game.pileCards, displaySize),
          Center(
              child: Image(
            image: AssetImage(
                'assets/cats/paw${catImageNumbers[aiSlapPlayerIndex!]}.png'),
            alignment: Alignment.center,
          )),
        ]);

      case AnimationMode.play_card_back:
        return Stack(children: [
          ..._pileCardWidgets(pileCardsWithoutLast, displaySize).toList(),
          if (lastPileCard != null)
            TweenAnimationBuilder(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 200),
              onEnd: () => setState(_playCardFinished),
              builder: (BuildContext context, double animValue, Widget? child) {
                double startYOff = displaySize.height /
                    2 *
                    (lastPileCard.playedBy == 0 ? 1 : -1);
                return Transform.translate(
                  offset: Offset(0, startYOff * (1 - animValue)),
                  child: _pileCardWidget(lastPileCard, displaySize,
                      rotationFrac: animValue),
                );
              },
            ),
        ]);

      case AnimationMode.pile_to_winner:
        double endYOff =
            displaySize.height * 0.75 * (pileMovingToPlayer == 0 ? 1 : -1);
        return TweenAnimationBuilder(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300),
          onEnd: () => setState(_movePileToWinner),
          child: Stack(children: _pileCardWidgets(game.pileCards, displaySize)),
          builder: (BuildContext context, double animValue, Widget? child) {
            return Transform.translate(
              offset: Offset(0, endYOff * animValue),
              child: child,
            );
          },
        );

      case AnimationMode.illegal_slap:
        final pc = this.penaltyCard;
        return Stack(children: [
          if (pc != null)
            TweenAnimationBuilder(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: illegalSlapAnimationDuration,
              builder: (BuildContext context, double animValue, Widget? child) {
                double startYOff =
                    displaySize.height / 2 * (pc.playedBy == 0 ? 1 : -1);
                return Transform.translate(
                  offset: Offset(0, startYOff * (1 - animValue)),
                  child:
                      _pileCardWidget(pc, displaySize, rotationFrac: animValue),
                );
              },
            ),
          Opacity(
              opacity: penaltyCard != null ? 0.25 : 1.0,
              child: Stack(
                children: _pileCardWidgets(
                    penaltyCard != null
                        ? game.pileCards.sublist(1)
                        : game.pileCards,
                    displaySize),
              )),
          TweenAnimationBuilder(
            tween: Tween(begin: 2.0, end: 0.0),
            duration: illegalSlapAnimationDuration,
            child: Center(
                child: Image(
              image: AssetImage('assets/misc/no.png'),
              alignment: Alignment.center,
            )),
            builder: (BuildContext context, double animValue, Widget? child) {
              return Opacity(
                opacity: min(animValue, 1),
                child: child,
              );
            },
          ),
        ]);

      default:
        return SizedBox.shrink();
    }
  }

  Widget _noSlapWidget(final int playerIndex, final Size displaySize) {
    return NoSlapIndicator(
      playerIndex: playerIndex,
      numTimeoutCards: game.slapTimeoutCardsForPlayer(playerIndex),
      displaySize: displaySize,
      catImageNumber: catImageNumbers[playerIndex],
    );
  }

  Widget _paddingAll(final double paddingPx, final Widget child) {
    return Padding(padding: EdgeInsets.all(paddingPx), child: child);
  }

  TableRow _makeButtonRow(String title, void Function() onPressed) {
    return TableRow(children: [
      Padding(
        padding: EdgeInsets.all(8),
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(title),
        ),
      ),
    ]);
  }

  // Main menu moved to a separate bottom-sheet widget in lib/main_menu_sheet.dart

  // Paused menu moved to lib/paused_menu_sheet.dart

  Widget _gameOverDialog(final Size displaySize) {
    final winner = game.gameWinner();
    if (winner == null) {
      return Container();
    }
    String title = (aiMode == AIMode.human_vs_ai)
        ? (winner == 0 ? 'You won!' : 'You lost!')
        : 'Player ${winner + 1} won!';
    return Container(
        width: double.infinity,
        height: double.infinity,
        child: Center(
            child: Dialog(
                backgroundColor: dialogBackgroundColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _paddingAll(
                        10,
                        Text(title,
                            style: TextStyle(
                              fontSize: min(displaySize.width / 15, 40),
                            ))),
                    _paddingAll(
                        10,
                        Table(
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          defaultColumnWidth: const IntrinsicColumnWidth(),
                          children: [
                            _makeButtonRow("Rematch", _startNewGame),
                            _makeButtonRow("Main menu", _endGame),
                          ],
                        )),
                  ],
                ))));
  }

  void _startOnePlayerGame() {
    setState(() {
      aiMode = AIMode.human_vs_ai;
      dialogMode = DialogMode.none;
      menuButtonVisible = false;
      animationMode = AnimationMode.none;
      catImageNumbers = _randomCatImageNumbers();
      playerBackgrounds = _randomPlayerBackgrounds(catImageNumbers.length);
      aiSlapCounter++;
      game.startGame();
    });
  }

  void _startTwoPlayerGame() {
    setState(() {
      aiMode = AIMode.human_vs_human;
      dialogMode = DialogMode.none;
      menuButtonVisible = false;
      animationMode = AnimationMode.none;
      catImageNumbers = _randomCatImageNumbers();
      playerBackgrounds = _randomPlayerBackgrounds(catImageNumbers.length);
      aiSlapCounter++;
      game.startGame();
    });
  }

  void _startNewGame() {
    setState(() {
      dialogMode = DialogMode.none;
      menuButtonVisible = false;
      animationMode = AnimationMode.none;
      aiSlapCounter++;
      game.startGame();
    });
  }

  void _continueGame() {
    setState(() {
      dialogMode = DialogMode.none;
      menuButtonVisible = false;
    });
  }

  void _endGame() {
    setState(() {
      dialogMode = DialogMode.none;
      aiMode = AIMode.ai_vs_ai;
      menuButtonVisible = false;
      animationMode = AnimationMode.none;
      aiSlapCounter++;
      game.startGame();
      _scheduleAiPlayIfNeeded();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fullDisplaySize = MediaQuery.sizeOf(context);
      final displayPadding = MediaQuery.paddingOf(context);
      final displaySize = Size(
          fullDisplaySize.width - displayPadding.left - displayPadding.right,
          fullDisplaySize.height - displayPadding.top - displayPadding.bottom);
      _showMenu(context, displaySize);
    });
  }

  void _closePreferences() {
    setState(() {
      dialogMode = DialogMode.none;
      menuButtonVisible = false;
    });
    if (aiMode == AIMode.ai_vs_ai) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final fullDisplaySize = MediaQuery.sizeOf(context);
        final displayPadding = MediaQuery.paddingOf(context);
        final displaySize = Size(
            fullDisplaySize.width - displayPadding.left - displayPadding.right,
            fullDisplaySize.height -
                displayPadding.top -
                displayPadding.bottom);
        _showMenu(context, displaySize);
      });
    }
  }

  void _watchAiGame() {
    setState(() {
      dialogMode = DialogMode.none;
      // Mark that the menu FAB should be visible because user chose "Watch the cats"
      menuButtonVisible = true;
      if (aiMode != AIMode.ai_vs_ai) {
        aiMode = AIMode.ai_vs_ai;
        game.startGame();
        _scheduleAiPlayIfNeeded();
      }
    });
  }

  Widget _menuIcon(final Size displaySize) {
    return Padding(
      padding: EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showMenu(context, displaySize),
                child: Icon(
                  aiMode == AIMode.ai_vs_ai
                      ? Icons.menu_rounded
                      : Icons.pause_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, Size displaySize) async {
    if (aiMode == AIMode.ai_vs_ai) {
      setState(() => menuOpen = true);
      await showMainMenuBottomSheet(
        context,
        displaySize,
        onOnePlayer: _startOnePlayerGame,
        onTwoPlayer: _startTwoPlayerGame,
        onWatchAi: _watchAiGame,
        onPreferences: () =>
            setState(() => dialogMode = DialogMode.preferences),
        onAbout: (ctx) => _showAboutDialog(ctx),
        preferences: preferences,
        game: game,
        aiSlapSpeed: aiSlapSpeed,
        onAiSlapSpeedChanged: (speed) => setState(() => aiSlapSpeed = speed),
        onSoundEnabledChanged: setSoundEnabled,
        onMusicEnabledChanged: setMusicEnabled,
        soundPlayer: soundPlayer,
      );
      if (mounted) setState(() => menuOpen = false);
    } else {
      setState(() => menuOpen = true);
      await showPausedMenuBottomSheet(
        context,
        displaySize,
        onContinue: _continueGame,
        onEnd: _endGame,
      );
      if (mounted) setState(() => menuOpen = false);
    }
  }

  void _showAboutDialog(BuildContext context) async {
    final aboutText =
        await DefaultAssetBundle.of(context).loadString('assets/doc/about.md');
    showAboutDialog(
      context: context,
      applicationName: appTitle,
      applicationVersion: appVersion,
      applicationLegalese: appLegalese,
      children: [
        Container(height: 15),
        MarkdownBody(
          data: aboutText,
          onTapLink: (text, href, title) => launch(href!),
          // https://github.com/flutter/flutter_markdown/issues/311
          listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
        ),
      ],
    );
  }

  bool _isGameActive() {
    try {
      return game.playerCards.isNotEmpty &&
          (game.playerCards[0].isNotEmpty || game.playerCards[1].isNotEmpty);
    } catch (e) {
      return false;
    }
  }

  void setSoundEnabled(bool enabled) {
    setState(() {
      soundPlayer.enabled = enabled;
    });
    preferences.setBool(soundEnabledPrefsKey, enabled);
    if (Random().nextBool()) {
      soundPlayer.playMadSound();
    } else {
      soundPlayer.playHappySound();
    }
  }

  void setMusicEnabled(bool enabled) {
    setState(() {
      soundPlayer.setMusicEnabled(enabled);
    });
    preferences.setBool(musicEnabledPrefsKey, enabled);
  }

  Widget _preferencesDialog(final Size displaySize) {
    final minDim = displaySize.shortestSide;
    final maxDim = displaySize.longestSide;
    final baseFontSize = min(maxDim / 36.0, minDim / 20.0);
    final titleFontSize = baseFontSize * 1.3;

    final makeRuleCheckboxRow =
        (String title, RuleVariation v, [double fontScale = 1.0]) {
      return CheckboxListTile(
        dense: true,
        title:
            Text(title, style: TextStyle(fontSize: baseFontSize * fontScale)),
        isThreeLine: false,
        onChanged: (bool? checked) {
          setState(() => game.rules.setVariationEnabled(v, checked == true));
          this.preferences.setBool(prefsKeyForVariation(v), checked == true);
        },
        value: game.rules.isVariationEnabled(v),
      );
    };

    final makeAiSpeedRow = () {
      final menuItemStyle = TextStyle(
          fontSize: baseFontSize * 0.9,
          color: Colors.blue,
          fontWeight: FontWeight.bold);
      return _paddingAll(
        0,
        ListTile(
            title: Text('Cat slap speed:',
                style: TextStyle(fontSize: baseFontSize)),
            trailing: DropdownButton(
              value: aiSlapSpeed,
              onChanged: (AISlapSpeed? value) {
                setState(() => aiSlapSpeed = value!);
                this
                    .preferences
                    .setString(aiSlapSpeedPrefsKey, value.toString());
              },
              items: [
                DropdownMenuItem(
                    value: AISlapSpeed.slow,
                    child: Text('Slow', style: menuItemStyle)),
                DropdownMenuItem(
                    value: AISlapSpeed.medium,
                    child: Text('Medium', style: menuItemStyle)),
                DropdownMenuItem(
                    value: AISlapSpeed.fast,
                    child: Text('Fast', style: menuItemStyle)),
              ],
            )),
      );
    };

    final makeSlapPenaltyRow = () {
      final menuItemStyle = TextStyle(
          fontSize: baseFontSize * 0.9,
          color: Colors.blue,
          fontWeight: FontWeight.bold);
      return DropdownButton(
        value: game.rules.badSlapPenalty,
        onChanged: (BadSlapPenaltyType? p) {
          setState(() => game.rules.badSlapPenalty = p!);
          this.preferences.setString(badSlapPenaltyPrefsKey, p.toString());
        },
        items: [
          DropdownMenuItem(
              value: BadSlapPenaltyType.none,
              child: Text('None', style: menuItemStyle)),
          DropdownMenuItem(
              value: BadSlapPenaltyType.penalty_card,
              child: Text('Penalty card', style: menuItemStyle)),
          DropdownMenuItem(
              value: BadSlapPenaltyType.slap_timeout,
              child: Text("Can't slap for next 5 cards", style: menuItemStyle)),
          DropdownMenuItem(
              value: BadSlapPenaltyType.opponent_wins_pile,
              child: Text('Opponent wins pile', style: menuItemStyle)),
        ],
      );
    };

    final dialogWidth = 0.8 * minDim;
    final dialogPadding = (displaySize.width - dialogWidth) / 2;
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Dialog(
        insetPadding:
            EdgeInsets.only(left: dialogPadding, right: dialogPadding),
        backgroundColor: dialogBackgroundColor,
        child: Padding(
          padding: EdgeInsets.all(minDim * 0.03),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Preferences', style: TextStyle(fontSize: titleFontSize)),
              Flexible(
                  child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                          primary: true,
                          child: Container(
                              color: dialogTableBackgroundColor,
                              child: Column(children: [
                                CheckboxListTile(
                                  dense: true,
                                  title: Text("Enable sound",
                                      style: TextStyle(fontSize: baseFontSize)),
                                  value: soundPlayer.enabled,
                                  onChanged: (bool? checked) {
                                    setSoundEnabled(checked == true);
                                  },
                                ),
                                makeAiSpeedRow(),
                                makeRuleCheckboxRow('Tens are stoppers',
                                    RuleVariation.ten_is_stopper),
                                SizedBox(height: baseFontSize * 0.25),
                                Row(children: [
                                  Text('Slap on:',
                                      style: TextStyle(fontSize: baseFontSize))
                                ]),
                                makeRuleCheckboxRow('Sandwiches',
                                    RuleVariation.slap_on_sandwich, 0.85),
                                makeRuleCheckboxRow('Run of 3',
                                    RuleVariation.slap_on_run_of_3, 0.85),
                                makeRuleCheckboxRow('4 of same suit',
                                    RuleVariation.slap_on_same_suit_of_4, 0.85),
                                makeRuleCheckboxRow('Adds to 10',
                                    RuleVariation.slap_on_add_to_10, 0.85),
                                makeRuleCheckboxRow('Marriages',
                                    RuleVariation.slap_on_marriage, 0.85),
                                makeRuleCheckboxRow('Divorces',
                                    RuleVariation.slap_on_divorce, 0.85),
                                Container(height: baseFontSize * 0.25),
                                Row(children: [
                                  Text('Penalty for wrong slap:',
                                      style: TextStyle(fontSize: baseFontSize))
                                ]),
                                Row(children: [makeSlapPenaltyRow()]),
                              ]))))),
              SizedBox(height: 15, width: 0),
              ElevatedButton(
                onPressed: _closePreferences,
                child: Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // A Fluttter bug causes most animations to take nearly zero time if the
  // ""Transition animation scale" option is set to off. This makes the game
  // unplayable, so we try to detect it by running a test animation on startup.
  // If the animation finishes much faster than it's supposed to, we're probably
  // in that condition and we notify the user.
  // See https://github.com/flutter/flutter/issues/164287
  bool runningTimingTestAnimation = false;
  int timingTestAnimationStartTimestamp = 0;

  void runAnimationTimingTestIfNeeded() {
    if (!kIsWeb && Platform.isAndroid) {
      Future.delayed(Duration(milliseconds: 1000), () {
        setState(() {
          timingTestAnimationStartTimestamp =
              DateTime.now().millisecondsSinceEpoch;
          runningTimingTestAnimation = true;
          // print("*** Started test animation");
        });
      });
    }
  }

  Widget timingTestAnimation() {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(seconds: 3),
      onEnd: timingTestAnimationFinished,
      child: const Positioned(
          left: 0, top: 0, height: 0, width: 0, child: SizedBox()),
      builder: (BuildContext context, double animMillis, Widget? child) {
        return child!;
      },
    );
  }

  void timingTestAnimationFinished() {
    int elapsed = DateTime.now().millisecondsSinceEpoch -
        timingTestAnimationStartTimestamp;
    // print("*** test animation done, elapsed: $elapsed");
    if (elapsed < 1000) {
      setState(() {
        dialogMode = DialogMode.animation_speed_warning;
      });
    }
  }

  Widget animationSpeedWarningDialog(final Size displaySize) {
    String animationMessage =
        'If animations are too fast, check the "Transition animation scale" option in the Settings app and make sure it\'s not set to "off".';
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Dialog(
          backgroundColor: dialogBackgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(animationMessage,
                      style: TextStyle(
                        fontSize: 20,
                      ))),
              Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        dialogMode = DialogMode.main_menu;
                      });
                    },
                    child: Text('OK'),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // displayPadding accounts for display cutouts which we don't want to draw over.
    final fullDisplaySize = MediaQuery.sizeOf(context);
    final displayPadding = MediaQuery.paddingOf(context);
    final displaySize = Size(
        fullDisplaySize.width - displayPadding.left - displayPadding.right,
        fullDisplaySize.height - displayPadding.top - displayPadding.bottom);

    final playerHeight = 120.0; // displaySize.height / 9;

    const cardAreaBackgroundColor = Color.fromARGB(255, 0, 128, 0);

    return Scaffold(
      body: AnimatedBackgroundWidget(
        child: Padding(
          padding: displayPadding,
          child: Center(
            child: Stack(
              children: [
                // Use a stack with the card pile last so that the cards will draw
                // over the player areas when they're animating in.
                Stack(
                  children: [
                    if (runningTimingTestAnimation) timingTestAnimation(),
                    // Top-player background that extends under the table by 30px.
                    Positioned(
                      left: 0,
                      width: displaySize.width,
                      top: 0,
                      // extend 30px below the player area so it goes "sotto il tavolo"
                      height: playerHeight + 30,
                      child: TopPlayerBackground(
                        visible: aiMode != AIMode.human_vs_human,
                        imagePath: (playerBackgrounds.isNotEmpty &&
                                playerBackgrounds.length > 1)
                            ? playerBackgrounds[1]
                            : null,
                      ),
                    ),
                    // Top player area with sparkle background
                    Positioned(
                      left: 0,
                      width: displaySize.width,
                      top: 0,
                      height: playerHeight,
                      child: Stack(
                        children: [
                          SparkleBackground(playerIndex: 1),
                          Container(
                              height: playerHeight,
                              width: double.infinity,
                              child: aiMode == AIMode.human_vs_human
                                  ? _playerStatusWidget(game, 1, displaySize)
                                  : _aiPlayerWidget(game, 1, displaySize)),
                        ],
                      ),
                    ),
                    // Bottom-player background that extends above the table by 30px.
                    Positioned(
                      left: 0,
                      width: displaySize.width,
                      top: displaySize.height - playerHeight - 30,
                      // extend 30px above the player area so it goes "sopra il tavolo"
                      height: playerHeight + 30,
                      child: TopPlayerBackground(
                        visible: aiMode != AIMode.human_vs_human,
                        imagePath: (playerBackgrounds.isNotEmpty)
                            ? playerBackgrounds[0]
                            : null,
                      ),
                    ),
                    // Bottom player area with sparkle background
                    Positioned(
                      left: 0,
                      width: displaySize.width,
                      top: displaySize.height - playerHeight,
                      height: playerHeight,
                      child: Stack(
                        children: [
                          SparkleBackground(playerIndex: 0),
                          Container(
                              height: playerHeight,
                              width: double.infinity,
                              child: aiMode == AIMode.ai_vs_ai
                                  ? _aiPlayerWidget(game, 0, displaySize)
                                  : _playerStatusWidget(game, 0, displaySize)),
                        ],
                      ),
                    ),
                    // Card area with decorative felt border
                    Positioned(
                      left: 0,
                      width: displaySize.width,
                      top: playerHeight,
                      height: displaySize.height - 2 * playerHeight,
                      child: FeltTableBorder(
                        child: Container(
                          color: cardAreaBackgroundColor,
                          child: Stack(children: [
                            Container(
                              child: _pileContent(game, displaySize),
                            ),
                            _noSlapWidget(0, displaySize),
                            _noSlapWidget(1, displaySize),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),

                if (dialogMode == DialogMode.game_over)
                  _gameOverDialog(displaySize),
                if (dialogMode == DialogMode.preferences)
                  _preferencesDialog(displaySize),
                if (dialogMode == DialogMode.animation_speed_warning)
                  animationSpeedWarningDialog(displaySize),
                if (dialogMode == DialogMode.none &&
                    !menuOpen &&
                    (menuButtonVisible || _isGameActive()))
                  _menuIcon(displaySize),
                // Text(this.animationMode.toString()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
