import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../features/story_buddy/providers/audio_provider.dart';
import '../../features/story_buddy/providers/quiz_provider.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

class AudioService with WidgetsBindingObserver {
  final Ref _ref;

  // Three separate players — no conflicts
  final AudioPlayer _storyPlayer   = AudioPlayer();
  final AudioPlayer _questionPlayer = AudioPlayer();
  final AudioPlayer _feedbackPlayer = AudioPlayer();
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;

  // Question audio files list
  final List<String> _questionAudios = [
    'assets/audio/question_1.mp3',
    'assets/audio/question_2..mp3', // Map to double dot filename on disk
    'assets/audio/question_3.mp3',
    'assets/audio/question_4.mp3',
    'assets/audio/question_5.mp3',
  ];

  AudioService(this._ref) {
    WidgetsBinding.instance.addObserver(this);
  }

  // ── STORY AUDIO ──────────────────
  Future<void> playStory({required WidgetRef ref}) async {
    try {
      _ref.read(audioStateProvider.notifier).setPreparing();
      _ref.read(storyPartProvider.notifier).reset();

      await _storyPlayer.setAsset('assets/audio/story_narration.mp3');

      // Track story parts by position
      _positionSub?.cancel();
      _positionSub = _storyPlayer.positionStream.listen((position) {
        final seconds = position.inSeconds;
        if (seconds < 10) {
          _ref.read(storyPartProvider.notifier).setPartIndex(0);
        } else if (seconds < 20) {
          _ref.read(storyPartProvider.notifier).setPartIndex(1);
        } else if (seconds < 30) {
          _ref.read(storyPartProvider.notifier).setPartIndex(2);
        } else {
          _ref.read(storyPartProvider.notifier).setPartIndex(3);
        }
      });

      // Track story completion
      _stateSub?.cancel();
      _stateSub = _storyPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _ref.read(audioStateProvider.notifier).setCompleted();
        }
      });

      _ref.read(audioStateProvider.notifier).setPlaying();
      await _storyPlayer.play();
    } catch (e) {
      _ref.read(audioStateProvider.notifier).setError();
    }
  }

  Future<void> stopStory() async {
    try {
      await _storyPlayer.stop();
      await _storyPlayer.seek(Duration.zero);
    } catch (e) {
      debugPrint('Stop story error: $e');
    }
  }

  // ── QUESTION AUDIO ───────────────
  Future<void> playQuestion(int index) async {
    try {
      await _questionPlayer.stop();
      await _questionPlayer.setAsset(_questionAudios[index]);
      await _questionPlayer.play();
    } catch (e) {
      debugPrint('Question audio error: $e');
    }
  }

  Future<void> stopQuestion() async {
    try {
      await _questionPlayer.stop();
    } catch (e) {
      debugPrint('Stop question error: $e');
    }
  }

  // ── FEEDBACK AUDIO ───────────────
  Future<void> playCorrect() async {
    try {
      // Stop everything else first
      await _questionPlayer.stop();
      await _storyPlayer.stop();

      await Future.delayed(const Duration(milliseconds: 200));

      await _feedbackPlayer.stop();
      await _feedbackPlayer.setAsset('assets/audio/correct_1.mp3');
      await _feedbackPlayer.play();

      // Wait for completion
      await _feedbackPlayer.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      );
    } catch (e) {
      debugPrint('Correct audio error: $e');
    }
  }

  Future<void> playWrong() async {
    try {
      // Stop everything else first
      await _questionPlayer.stop();
      await _storyPlayer.stop();

      await Future.delayed(const Duration(milliseconds: 200));

      await _feedbackPlayer.stop();
      await _feedbackPlayer.setAsset('assets/audio/wrong_1.mp3');
      await _feedbackPlayer.play();

      // Wait for completion
      await _feedbackPlayer.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      );
    } catch (e) {
      debugPrint('Wrong audio error: $e');
    }
  }

  // ── STOP ALL ─────────────────────
  Future<void> stopAll() async {
    try {
      await _storyPlayer.stop();
      await _questionPlayer.stop();
      await _feedbackPlayer.stop();
    } catch (e) {
      debugPrint('Stop all error: $e');
    }
  }

  Future<void> stop() async {
    await stopAll();
    _ref.read(audioStateProvider.notifier).setIdle();
  }

  // ── APPLIFECYCLE ─────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      stopAll();
    }
  }

  // ── DISPOSE ──────────────────────
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionSub?.cancel();
    _stateSub?.cancel();
    _storyPlayer.dispose();
    _questionPlayer.dispose();
    _feedbackPlayer.dispose();
  }
}
