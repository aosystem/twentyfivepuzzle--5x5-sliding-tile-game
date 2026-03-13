import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class AudioPlay {
  late AudioPlayer _audioPlayer;
  double _soundVolume = 0.0;

  AudioPlay() {
    _constructor();
  }

  void _constructor() async {
    _audioPlayer = AudioPlayer();
    unawaited(_audioPlayer.setReleaseMode(ReleaseMode.stop));
    unawaited(_audioPlayer.setPlayerMode(PlayerMode.lowLatency));
    await _audioPlayer.setSource(AssetSource('sound/glass.wav'));
  }

  void dispose() {
    _audioPlayer.dispose();
  }

  void setVolume(double value) async {
    _soundVolume = value;
    await _audioPlayer.setVolume(value);
  }

  void play01() async {
    if (_soundVolume == 0) {
      return;
    }
    try {
      await _audioPlayer.stop();
      await _audioPlayer.resume();
    } catch (_) {
    }
  }

}
