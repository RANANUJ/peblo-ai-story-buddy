import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AudioState { idle, preparing, playing, completed, error }

class AudioNotifier extends StateNotifier<AudioState> {
  AudioNotifier() : super(AudioState.idle);

  void setIdle() => state = AudioState.idle;
  void setPreparing() => state = AudioState.preparing;
  void setPlaying() => state = AudioState.playing;
  void setCompleted() => state = AudioState.completed;
  void setError() => state = AudioState.error;
}

final audioStateProvider = StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  return AudioNotifier();
});
