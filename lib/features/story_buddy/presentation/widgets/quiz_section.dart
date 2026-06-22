import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../data/models/quiz_model.dart';
import '../widgets/option_tile.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/buddy_provider.dart';
import '../../../../core/theme/peblo_theme.dart';

class QuizSection extends ConsumerStatefulWidget {
  final QuizModel quiz;

  const QuizSection({
    super.key,
    required this.quiz,
  });

  @override
  ConsumerState<QuizSection> createState() => _QuizSectionState();
}

class _QuizSectionState extends ConsumerState<QuizSection> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _successBannerController;
  late Animation<double> _successScaleAnimation;

  late ConfettiController _confettiController;

  final List<String> _emojis = ['❤️', '⭐', '🌈', '🎨', '🚀'];
  
  // Option colors representing option index (PRD Section 7.4 / 9.5)
  final List<Color> _optionColors = [
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.teal,
    Colors.deepPurpleAccent,
    PebloTheme.goldenYellow,
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.25), // Slide up from 25% height below
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));

    _successBannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScaleAnimation = CurvedAnimation(
      parent: _successBannerController,
      curve: Curves.elasticOut,
    );

    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // Listen to state changes to trigger entry animation
    _checkQuizState();
  }

  @override
  void didUpdateWidget(covariant QuizSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkQuizState();
  }

  void _checkQuizState() {
    final quizState = ref.read(quizStateProvider);
    if (quizState.status == QuizStatus.revealing) {
      _entryController.forward().then((_) {
        // Move to awaiting answer once the entrance animation completes
        if (mounted && ref.read(quizStateProvider).status == QuizStatus.revealing) {
          ref.read(quizStateProvider.notifier).setAwaitingAnswer();
          ref.read(buddyStateProvider.notifier).setPointing();
        }
      });
    } else if (quizState.status == QuizStatus.correct) {
      _confettiController.play();
      _successBannerController.forward();
    } else if (quizState.status == QuizStatus.hidden) {
      _entryController.reset();
      _successBannerController.reset();
      _confettiController.stop();
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _successBannerController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Color _getConfettiColor() {
    final correctIndex = widget.quiz.options.indexOf(widget.quiz.answer);
    if (correctIndex == -1) return PebloTheme.goldenYellow;
    return _optionColors[correctIndex % _optionColors.length];
  }

  void _handleOptionTap(String option) {
    final quizState = ref.read(quizStateProvider);
    if (quizState.status != QuizStatus.awaitingAnswer) return; // Prevent double taps during evaluations

    final isCorrectOption = option == widget.quiz.answer;
    
    // 1. Select the option
    ref.read(quizStateProvider.notifier).selectOption(option);

    if (isCorrectOption) {
      // 2. Correct state: trigger confetti + celebrate
      ref.read(quizStateProvider.notifier).setCorrect();
      ref.read(buddyStateProvider.notifier).setCelebrating();
      _confettiController.play();
      _successBannerController.forward();
    } else {
      // 3. Wrong state: trigger shake, set sympathetic, wait 600ms and reset
      ref.read(quizStateProvider.notifier).setWrong();
      ref.read(buddyStateProvider.notifier).setSympathetic();

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          final currentState = ref.read(quizStateProvider);
          // Only reset if we are still in the wrong state (wasn't corrected in between)
          if (currentState.status == QuizStatus.wrong) {
            ref.read(quizStateProvider.notifier).setAwaitingAnswer();
            ref.read(buddyStateProvider.notifier).setPointing();
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizStateProvider);

    if (quizState.status == QuizStatus.hidden) {
      return const SizedBox.shrink();
    }

    final hasHint = widget.quiz.hint != null && widget.quiz.hint!.isNotEmpty;
    // Show hint tooltip after 2 wrong attempts (PRD Section 9.3)
    final showHint = quizState.wrongAttempts >= 2 && hasHint;

    // Get color matching correct option's color (PRD Section 9.5)
    final correctConfettiColor = _getConfettiColor();

    return Stack(
      alignment: Alignment.center,
      children: [
        // CONFETTI LAUNCHER: RepaintBoundary wraps the ConfettiWidget to isolate ticks (PRD Section 9.5 / 11.2)
        RepaintBoundary(
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive, // Shoot everywhere
            shouldLoop: false,
            colors: [
              correctConfettiColor,
              correctConfettiColor.withOpacity(0.8),
              correctConfettiColor.withOpacity(0.6),
            ],
            numberOfParticles: 20, // Optimized for lower RAM devices (PRD Section 11.2)
          ),
        ),
        
        FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Quiz Header Card
                Card(
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PebloTheme.borderRadius),
                    side: const BorderSide(color: PebloTheme.skyTeal, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.psychology_alt_rounded, color: PebloTheme.skyTeal, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              "Quick Quiz!",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: PebloTheme.skyTeal,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.quiz.question,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Hint Tooltip (Whisper Hint Mode - PRD Section 9.3)
                if (showHint) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: PebloTheme.goldenYellow.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(PebloTheme.borderRadius),
                      border: Border.all(color: PebloTheme.goldenYellow, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_rounded, color: PebloTheme.goldenYellow, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Pip's Hint",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.quiz.hint!,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Data-Driven Options ListView
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Scroll managed by parent
                  itemCount: widget.quiz.options.length,
                  itemBuilder: (context, index) {
                    final option = widget.quiz.options[index];
                    final isSelected = quizState.selectedOption == option;
                    final isCorrect = quizState.status == QuizStatus.correct && isSelected;
                    final isWrong = quizState.status == QuizStatus.wrong && isSelected;

                    // Emoji prefix matching option index
                    final emoji = _emojis[index % _emojis.length];
                    final optionText = "$emoji  $option";

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: OptionTile(
                        text: optionText,
                        isSelected: isSelected,
                        isCorrect: isCorrect,
                        isWrong: isWrong,
                        onTap: () => _handleOptionTap(option),
                      ),
                    );
                  },
                ),

                // Success Overlay Message Block: Pop-in bouncy scale animation (PRD Section 9.5)
                if (quizState.status == QuizStatus.correct) ...[
                  const SizedBox(height: 16),
                  ScaleTransition(
                    scale: _successScaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: PebloTheme.successGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(PebloTheme.borderRadius),
                        border: Border.all(color: PebloTheme.successGreen, width: 2),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: PebloTheme.successGreen, size: 28),
                          SizedBox(width: 10),
                          Text(
                            "You got it! Brilliant! 🎉",
                            style: TextStyle(
                              color: PebloTheme.successGreen,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
