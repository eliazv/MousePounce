import 'dart:math';

import 'package:just_audio/just_audio.dart';

class SoundEffectPlayer {
  final rng = Random();
  final madSoundPlayers = <AudioPlayer>[];
  final happySoundPlayers = <AudioPlayer>[];
  AudioPlayer? deckRedrawPlayer;
  AudioPlayer? placeCardPlayer;
  AudioPlayer? winPlayer;
  AudioPlayer? backgroundMusicPlayer;
  bool enabled = false;
  bool musicEnabled = false;
  bool soundsLoaded = false;

  void init() async {
    soundsLoaded = false;

    madSoundPlayers.clear();
    madSoundPlayers.add(await _makePlayer('sauerkraut_mad_1.mp3'));
    madSoundPlayers.add(await _makePlayer('sauerkraut_mad_2.mp3'));
    madSoundPlayers.add(await _makePlayer('sauerkraut_mad_3.mp3'));
    madSoundPlayers.add(await _makePlayer('ginger_mad_1.mp3'));
    madSoundPlayers.add(await _makePlayer('ginger_mad_2.mp3'));

    happySoundPlayers.clear();
    happySoundPlayers.add(await _makePlayer('boojie_happy_1.mp3'));
    happySoundPlayers.add(await _makePlayer('boojie_happy_2.mp3'));
    happySoundPlayers.add(await _makePlayer('boojie_happy_3.mp3'));
    happySoundPlayers.add(await _makePlayer('boojie_happy_4.mp3'));

    // Load new sound effects
    deckRedrawPlayer = await _makePlayer('deck_redraw.wav');
    placeCardPlayer = await _makePlayer('place.wav');
    winPlayer = await _makePlayer('win.wav');

    // Load background music
    backgroundMusicPlayer = AudioPlayer();
    await backgroundMusicPlayer!.setAsset('assets/music/lofi.mp3');
    await backgroundMusicPlayer!.setLoopMode(LoopMode.one);
    await backgroundMusicPlayer!.setVolume(0.3);

    soundsLoaded = true;
  }

  int loopIndex = 0;

  void _playRandomSoundFrom(final List<AudioPlayer> players) async {
    if (!enabled || !soundsLoaded) {
      return;
    }
    final index = rng.nextInt(players.length);
    await players[index].seek(Duration.zero);
    await players[index].play();
  }

  void playMadSound() async {
    print("playMadSound");
    _playRandomSoundFrom(madSoundPlayers);
  }

  void playHappySound() async {
    print("playHappySound");
    _playRandomSoundFrom(happySoundPlayers);
  }

  void playDeckRedrawSound() async {
    if (!enabled || !soundsLoaded || deckRedrawPlayer == null) {
      return;
    }
    await deckRedrawPlayer!.seek(Duration.zero);
    await deckRedrawPlayer!.play();
  }

  void playPlaceCardSound() async {
    if (!enabled || !soundsLoaded || placeCardPlayer == null) {
      return;
    }
    await placeCardPlayer!.seek(Duration.zero);
    await placeCardPlayer!.play();
  }

  void playWinSound() async {
    if (!enabled || !soundsLoaded || winPlayer == null) {
      return;
    }
    await winPlayer!.seek(Duration.zero);
    await winPlayer!.play();
  }

  void startBackgroundMusic() async {
    if (!soundsLoaded || backgroundMusicPlayer == null) {
      return;
    }
    if (musicEnabled && !backgroundMusicPlayer!.playing) {
      await backgroundMusicPlayer!.play();
    }
  }

  void stopBackgroundMusic() async {
    if (backgroundMusicPlayer != null && backgroundMusicPlayer!.playing) {
      await backgroundMusicPlayer!.pause();
    }
  }

  void setMusicEnabled(bool enabled) {
    musicEnabled = enabled;
    if (enabled) {
      startBackgroundMusic();
    } else {
      stopBackgroundMusic();
    }
  }

  void dispose() {
    for (var player in madSoundPlayers) {
      player.dispose();
    }
    for (var player in happySoundPlayers) {
      player.dispose();
    }
    deckRedrawPlayer?.dispose();
    placeCardPlayer?.dispose();
    winPlayer?.dispose();
    backgroundMusicPlayer?.dispose();
  }
}

Future<AudioPlayer> _makePlayer(String filename) async {
  final player = AudioPlayer();
  await player.setAsset('assets/audio/$filename');
  return player;
}