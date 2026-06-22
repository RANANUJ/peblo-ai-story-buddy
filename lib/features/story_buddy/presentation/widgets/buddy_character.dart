import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/audio_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../../../core/constants/buddy_assets.dart';

class BuddyCharacter extends ConsumerWidget {
  const BuddyCharacter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioStateProvider);
    final quizState = ref.watch(quizStateProvider);

    // Resolve the active asset path based on state
    final String assetPath = _resolveAsset(audioState, quizState);
    
    // Handoff is active when audio is complete and the quiz is starting to reveal/await answer
    final isHandoff = quizState.status != QuizStatus.hidden && audioState == AudioState.completed;

    final isCorrect = quizState.status == QuizStatus.correct;

    Widget mainCharacter = AnimatedSwitcher(
      duration: Duration(milliseconds: isHandoff ? 600 : 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final childKey = child.key as ValueKey<String>?;
        final path = childKey?.value ?? '';

        if (!isHandoff) {
          // Standard state changes (e.g. idle -> speaking) use a simple, lightweight crossfade
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        }

        final isVidya = path.contains('vidya');
        if (isVidya) {
          // Vidya Entrance: Slides up from y+30 to y=0 with fade-in (starts after 200ms)
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.0, 30.0 / 160.0), // 30dp slide up offset based on 160dp widget height
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: const Interval(0.33, 1.0, curve: Curves.easeOutCubic), // Runs for the final 400ms
          ));

          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.33, 1.0, curve: Curves.easeIn),
          );

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        } else {
          // Raga Exit: Scales down to 0.6, slides left (dx: -20), and fades out (completes in 200ms)
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(-20.0 / 160.0, 0.0), // -20dp slide left offset
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.33, curve: Curves.easeIn), // Runs for the first 200ms
          ));

          final scaleAnimation = Tween<double>(
            begin: 0.6,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.33, curve: Curves.easeIn),
          ));

          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.33, curve: Curves.easeIn),
          );

          return SlideTransition(
            position: offsetAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            ),
          );
        }
      },
      child: Image.asset(
        assetPath,
        key: ValueKey(assetPath),
        height: 160,
        fit: BoxFit.contain,
      ),
    );

    if (isCorrect) {
      // PRD Section 16.4 & 9.5: Add small Raga in the corner giving thumbs up during correct answer celebration
      return RepaintBoundary(
        child: SizedBox(
          width: 200,
          height: 160,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              mainCharacter, // Vidya celebrating
              Positioned(
                bottom: -8,
                right: -24,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    RagaAssets.waveBye, // Raga waving / thumbs up
                    height: 64,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: mainCharacter,
    );
  }

  String _resolveAsset(AudioState audio, QuizState quiz) {
    // Quiz states take priority — Vidya owns the quiz section
    if (quiz.status == QuizStatus.correct) {
      return VidyaAssets.celebrating;
    }
    if (quiz.status == QuizStatus.wrong) {
      return VidyaAssets.sympathetic;
    }
    if (quiz.status == QuizStatus.awaitingAnswer || quiz.status == QuizStatus.revealing) {
      return VidyaAssets.pointing;
    }

    // Audio states — Raga owns the story section
    if (audio == AudioState.playing) {
      return RagaAssets.speaking;
    }
    if (audio == AudioState.preparing) {
      return RagaAssets.thinking;
    }
    if (audio == AudioState.error) {
      return RagaAssets.shy;
    }
    if (audio == AudioState.completed) {
      return RagaAssets.waveBye;
    }

    return RagaAssets.idle; // Default: Raga idle on app load
  }
}
