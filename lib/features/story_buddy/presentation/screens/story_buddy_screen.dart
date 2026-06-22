import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/audio_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/buddy_provider.dart';
import '../../data/models/quiz_model.dart';
import '../widgets/buddy_character.dart';
import '../widgets/story_card.dart';
import '../widgets/read_button.dart';
import '../widgets/quiz_section.dart';
import '../../../../core/theme/peblo_theme.dart';
import '../../../../core/services/tts_service.dart';

// Speech Bubble Painter for mascot dialog prompts
class SpeechBubblePainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  SpeechBubblePainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height - 12);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    final path = Path()
      ..addRRect(rrect)
      // Draw speech bubble triangle pointing downwards
      ..moveTo(size.width / 2 - 12, size.height - 12)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + 12, size.height - 12)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StoryBuddyScreen extends ConsumerWidget {
  const StoryBuddyScreen({super.key});

  static const String storyText =
      "Once upon a time, a clever little robot named Pip lost his shiny blue gear in the Whispering Woods...";

  // Static mock quiz data loaded from dynamic data spec (Section 7.1)
  static const QuizModel mockQuiz = QuizModel(
    question: "What colour was Pip the Robot's lost gear?",
    options: ["Red", "Green", "Blue", "Yellow"],
    answer: "Blue",
    hint: "Think about what colour the sky is!",
  );

  String _getBuddyBubbleText(AudioState audio, QuizState quiz) {
    if (quiz.status == QuizStatus.correct) {
      return "You got it! Brilliant! 🎉";
    }
    if (quiz.status == QuizStatus.wrong) {
      return "Almost! Try again! 🦉";
    }
    if (quiz.status == QuizStatus.awaitingAnswer || quiz.status == QuizStatus.revealing) {
      return "Can you answer my question? 🦉";
    }
    if (audio == AudioState.playing) {
      return "Listen to my adventure! 🐰";
    }
    if (audio == AudioState.preparing) {
      return "Getting my story ready... ✨";
    }
    if (audio == AudioState.error) {
      return "Oops! My voice got a bit shy. 🐰";
    }
    return "Tap below to hear my story! 🐰";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioStateProvider);
    final quizState = ref.watch(quizStateProvider);

    // Cross-provider state transition trigger (PRD Section 8.2)
    ref.listen<AudioState>(audioStateProvider, (prev, next) {
      if (next == AudioState.completed) {
        ref.read(quizStateProvider.notifier).revealQuiz();
        ref.read(buddyStateProvider.notifier).setPointing();
      }
    });

    final bubbleText = _getBuddyBubbleText(audioState, quizState);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar Navigation (Wireframe Section 5.3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo/Streak Info
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: PebloTheme.goldenYellow, size: 28),
                      const SizedBox(width: 6),
                      Text(
                        "PEBLO",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                      ),
                    ],
                  ),
                  // Lives / Settings
                  Row(
                    children: [
                      // Hearts
                      Row(
                        children: List.generate(
                          3,
                          (index) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2.0),
                            child: Icon(Icons.favorite_rounded, color: Colors.red, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.settings_rounded, color: PebloTheme.primaryPurple, size: 24),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Main Content Canvas
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  children: [
                    // Character Display & Dialogue Bubble (Raga / Vidya)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 250),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Speech bubble
                          CustomPaint(
                            painter: SpeechBubblePainter(
                              color: Colors.white,
                              borderColor: quizState.status != QuizStatus.hidden
                                  ? PebloTheme.skyTeal
                                  : PebloTheme.primaryPurple,
                            ),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                              child: Text(
                                bubbleText,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: quizState.status != QuizStatus.hidden
                                      ? PebloTheme.skyTeal
                                      : PebloTheme.primaryPurple,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Mascot Widget
                          const BuddyCharacter(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Story Text Card
                    const StoryCard(text: storyText),
                    const SizedBox(height: 24),

                    // Audio Execution CTA (ReadButton or Error State Handlers)
                    if (audioState == AudioState.error) ...[
                      // Friendly child message error card + retry options (PRD Section 12)
                      Card(
                        color: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(PebloTheme.borderRadius),
                          side: const BorderSide(color: PebloTheme.errorRed, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline_rounded, color: PebloTheme.errorRed, size: 26),
                                  SizedBox(width: 8),
                                  Text(
                                    "Oops! Voice got stuck!",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: PebloTheme.errorRed,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Retry TTS Narration
                                  ElevatedButton(
                                    onPressed: () => ref.read(ttsServiceProvider).retry(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: PebloTheme.errorRed,
                                      minimumSize: const Size(120, 48),
                                    ),
                                    child: const Text("Try Again"),
                                  ),
                                  // Read myself fallback bypass
                                  OutlinedButton(
                                    onPressed: () {
                                      // Force completion to bypass voice failure and slide up quiz
                                      ref.read(audioStateProvider.notifier).setCompleted();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: PebloTheme.primaryPurple,
                                      side: const BorderSide(color: PebloTheme.primaryPurple, width: 1.5),
                                      minimumSize: const Size(120, 48),
                                    ),
                                    child: const Text("Read Myself"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // General sound interaction button
                      ReadButton(
                        onTap: () {
                          ref.read(ttsServiceProvider).speak(storyText);
                        },
                      ),
                    ],

                    // Spacer/gap before quiz reveal
                    if (quizState.status != QuizStatus.hidden) const SizedBox(height: 24),

                    // Interactive Quiz Section (Loaded dynamically)
                    const QuizSection(quiz: mockQuiz),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
