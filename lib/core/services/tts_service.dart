import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/story_buddy/providers/audio_provider.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService(ref);
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

class TtsService with WidgetsBindingObserver {
  final Ref _ref;
  final FlutterTts _flutterTts = FlutterTts();
  String? _lastSpokenText;
  bool _isInitialized = false;

  TtsService(this._ref) {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Set up native engine event listeners
    _flutterTts.setStartHandler(() {
      _ref.read(audioStateProvider.notifier).setPlaying();
    });

    _flutterTts.setCompletionHandler(() {
      _ref.read(audioStateProvider.notifier).setCompleted();
    });

    _flutterTts.setErrorHandler((dynamic msg) {
      _ref.read(audioStateProvider.notifier).setError();
    });

    _flutterTts.setCancelHandler(() {
      _ref.read(audioStateProvider.notifier).setIdle();
    });

    // Configure standard child-friendly speech characteristics
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.45); // Slower speech rate for young learners
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.1); // Slightly higher pitch for a friendly, energetic voice

    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    _lastSpokenText = text;
    _ref.read(audioStateProvider.notifier).setPreparing();

    try {
      await initialize();
      final result = await _flutterTts.speak(text);
      if (result != 1) {
        _ref.read(audioStateProvider.notifier).setError();
      }
    } catch (e) {
      _ref.read(audioStateProvider.notifier).setError();
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _ref.read(audioStateProvider.notifier).setIdle();
    } catch (e) {
      _ref.read(audioStateProvider.notifier).setError();
    }
  }

  Future<void> retry() async {
    if (_lastSpokenText != null) {
      await speak(_lastSpokenText!);
    }
  }

  // App lifecycle pause/resume handling (PRD Section 12)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // Pause/Stop TTS when app goes into background
      final currentAudioState = _ref.read(audioStateProvider);
      if (currentAudioState == AudioState.playing || currentAudioState == AudioState.preparing) {
        stop();
      }
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flutterTts.stop();
  }
}
