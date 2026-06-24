import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../data/models/quiz_model.dart';
import '../widgets/option_tile.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/buddy_provider.dart';
import '../../providers/audio_provider.dart';
import '../../../../core/theme/peblo_theme.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/constants/buddy_assets.dart';

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

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  String? _localCorrectOption;
  
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

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

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
          // Auto play the first question audio
          ref.read(audioServiceProvider).playQuestion(0);
        }
      });
    } else if (quizState.status == QuizStatus.correct) {
      // Confetti fires with 300ms delay as part of Step 4
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && ref.read(quizStateProvider).status == QuizStatus.correct) {
          _confettiController.play();
          _successBannerController.forward();
        }
      });
    } else if (quizState.status == QuizStatus.completed) {
      _confettiController.play();
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
    _scaleController.dispose();
    super.dispose();
  }

  Color _getConfettiColor() {
    final correctIndex = widget.quiz.options.indexOf(widget.quiz.answer);
    if (correctIndex == -1) return PebloTheme.goldenYellow;
    return _optionColors[correctIndex % _optionColors.length];
  }

  Future<void> _handleOptionTap(String option) async {
    final quizState = ref.read(quizStateProvider);
    if (quizState.status != QuizStatus.awaitingAnswer) return; // Prevent double taps during evaluations

    // FIRST — stop question and story audio immediately (Step 2/3 of flow rules)
    await ref.read(audioServiceProvider).stopQuestion();
    await ref.read(audioServiceProvider).stopStory();

    final isCorrectOption = option == widget.quiz.answer;
    
    if (isCorrectOption) {
      // STEP 1 — Instant visual (0ms)
      setState(() {
        _localCorrectOption = option;
      });
      _scaleController.forward(from: 0.0);
      HapticFeedback.lightImpact();

      // Trigger correct answer flow (which handles delay, plays tune, and advances)
      await ref.read(quizStateProvider.notifier).handleAnswer(
        selectedOption: option,
        audioService: ref.read(audioServiceProvider),
        ref: ref,
      );

      // Clean up local correct option highlight
      if (mounted) {
        setState(() {
          _localCorrectOption = null;
        });
      }
    } else {
      // Trigger wrong answer flow
      await ref.read(quizStateProvider.notifier).handleAnswer(
        selectedOption: option,
        audioService: ref.read(audioServiceProvider),
        ref: ref,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizStateProvider);

    if (quizState.status == QuizStatus.hidden) {
      return const SizedBox.shrink();
    }

    if (quizState.status == QuizStatus.completed) {
      return _buildFinalSuccessScreen(quizState);
    }

    final hasHint = widget.quiz.hint.isNotEmpty;
    // Show hint tooltip on wrong attempt or awaiting answer
    final showHint = quizState.wrongAttempts >= 2 && hasHint;
    final correctConfettiColor = _getConfettiColor();

    return Stack(
      alignment: Alignment.center,
      children: [
        RepaintBoundary(
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: [
              correctConfettiColor,
              correctConfettiColor.withOpacity(0.8),
              correctConfettiColor.withOpacity(0.6),
            ],
            numberOfParticles: 20,
          ),
        ),
        
        // Main quiz card
        FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32.0),
                boxShadow: [
                  BoxShadow(
                    color: PebloTheme.primaryPurple.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32.0),
                  side: const BorderSide(
                    color: Color(0xFFE8DDFC),
                    width: 2.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Question Progress Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Question ${quizState.currentQuestionIndex + 1} of 5",
                            style: const TextStyle(
                              color: Color(0xFF330066),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Small sound button
                          IconButton(
                            onPressed: () {
                              ref.read(audioServiceProvider).playQuestion(quizState.currentQuestionIndex);
                            },
                            icon: const Icon(Icons.volume_up_rounded, color: PebloTheme.primaryPurple, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              shadowColor: Colors.black.withOpacity(0.1),
                              elevation: 2,
                              padding: const EdgeInsets.all(6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // 2. Dynamic Progress Bar
                      Container(
                        width: double.infinity,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8DDFC),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: quizState.currentQuestionIndex + 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: PebloTheme.primaryPurple,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 5 - (quizState.currentQuestionIndex + 1),
                              child: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 3. Question Text
                      Text(
                        widget.quiz.question,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF330066),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 4. Custom Letter-Badged Options List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.quiz.options.length,
                        itemBuilder: (context, index) {
                          final option = widget.quiz.options[index];
                          final isSelected = quizState.selectedOption == option;
                          final isCorrect = (quizState.status == QuizStatus.correct && isSelected) ||
                              (_localCorrectOption == option);
                          final isWrong = quizState.status == QuizStatus.wrong && isSelected;
                          final letter = String.fromCharCode(65 + index); // A, B, C, D

                          final optionTile = OptionTile(
                            text: option,
                            letter: letter,
                            isSelected: isSelected,
                            isCorrect: isCorrect,
                            isWrong: isWrong,
                            onTap: () => _handleOptionTap(option),
                          );

                          Widget tileWidget = optionTile;

                          // STEP 4: Show green checkmark on correct option
                          if (quizState.status == QuizStatus.correct && isSelected) {
                            tileWidget = Stack(
                              alignment: Alignment.centerRight,
                              children: [
                                optionTile,
                                const Padding(
                                  padding: EdgeInsets.only(right: 16.0),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            );
                          }

                          if (isCorrect) {
                            return ScaleTransition(
                              scale: _scaleAnimation,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: tileWidget,
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: tileWidget,
                          );
                        },
                      ),

                      // 5. Hint Tooltip (Whisper Hint Mode - PRD Section 9.3)
                      if (showHint) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded, color: Colors.orange, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.quiz.hint,
                                  style: const TextStyle(
                                    color: PebloTheme.primaryPurple,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Success message block (only for current question correct delay state)
                      if (quizState.status == QuizStatus.correct) ...[
                        const SizedBox(height: 10),
                        ScaleTransition(
                          scale: _successScaleAnimation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: PebloTheme.successGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: PebloTheme.successGreen, width: 2),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, color: PebloTheme.successGreen, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  "You got it! Brilliant! 🎉",
                                  style: TextStyle(
                                    color: PebloTheme.successGreen,
                                    fontSize: 16,
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalSuccessScreen(QuizState quizState) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        RepaintBoundary(
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFFFFD700), // Gold
              Colors.white,
              Colors.blue,
              Colors.lightBlueAccent,
            ],
            numberOfParticles: 35,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 24), // Leave space for ribbon
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32.0),
            boxShadow: [
              BoxShadow(
                color: PebloTheme.primaryPurple.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: const Color(0xFFFFFDF9), // Warm white card background
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32.0),
              side: const BorderSide(
                color: Color(0xFFFDE8E8), // soft warm border
                width: 2.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 36.0, 20.0, 24.0), // top padding adjusted for ribbon overlap
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title: You finished the story! flanked by sparkles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "✨",
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "You finished the story!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2D1B5C), // deep purple
                            shadows: [
                              Shadow(
                                color: Colors.orange.withOpacity(0.1),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "✨",
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Subtitle: You got X out of 5 right!
                  Text(
                    "You got ${quizState.firstTryCorrectCount} out of 5 right!",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B21A8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Stars Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final earned = index < quizState.firstTryCorrectCount;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Icon(
                          Icons.star_rounded,
                          color: earned ? const Color(0xFFFFB020) : Colors.grey.shade300,
                          size: 38,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  
                  // Mascot library scene banner + floating story explorer badge
                  Container(
                    height: 130,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Library scene image container
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFFD700), // Gold border
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                VidyaAssets.celebrating,
                                fit: BoxFit.cover,
                                alignment: const Alignment(0, -0.2), // align vertical to center the owl
                              ),
                            ),
                          ),
                        ),
                        // Floating explorer badge on the left
                        Positioned(
                          left: -12,
                          top: 15,
                          bottom: 15,
                          child: Container(
                            width: 105,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFFCC00),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "You're a",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "Story Explorer!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF330066),
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF7C3AED), // Purple
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orangeAccent,
                                        blurRadius: 2,
                                      )
                                    ]
                                  ),
                                  child: const Icon(
                                    Icons.menu_book_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Encouragement pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE9D5FF),
                        width: 1.5,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Keep going! More magical stories\nand quizzes are waiting for you.",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF5B21B6),
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.history_edu_rounded, color: Color(0xFF7C3AED), size: 18), // quill feather icon
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  
                  // Read Another Story Button (Vibrant Purple Gradient)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(audioServiceProvider).stop();
                        ref.read(quizStateProvider.notifier).resetQuiz();
                        ref.read(audioStateProvider.notifier).setIdle();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF8B5CF6),
                              Color(0xFF6D28D9),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6D28D9).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFDE047), // Yellow circle
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.menu_book_rounded,
                                  color: Color(0xFF6D28D9),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Read Another Story!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Ribbon Banner overlapping top
        Positioned(
          top: 10, // top position offset for overlapping the card
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF8B5CF6),
                  Color(0xFF6D28D9),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Text(
              "✦ Amazing! ✦",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Bouncing and rocking animation for the final celebration dancing mascot
class DancingMascot extends StatefulWidget {
  final String asset;
  const DancingMascot({super.key, required this.asset});

  @override
  State<DancingMascot> createState() => _DancingMascotState();
}

class _DancingMascotState extends State<DancingMascot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: -15.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0.0, _bounceAnimation.value),
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Image.asset(
              widget.asset,
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}
