import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../providers/audio_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/buddy_provider.dart';
import '../../data/models/quiz_model.dart';
import '../widgets/buddy_character.dart';
import '../widgets/story_card.dart';
import '../widgets/quiz_section.dart';
import '../../../../core/theme/peblo_theme.dart';
import '../../../../core/services/tts_service.dart';

// Custom painter to draw bushes with flowers at the bottom left and bottom right corners
class FloralBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Paints for the layered bushes
    final darkGreenPaint = Paint()..color = const Color(0xFF386641); // Forest green
    final midGreenPaint = Paint()..color = const Color(0xFF6A994E);  // Leaf green
    final lightGreenPaint = Paint()..color = const Color(0xFFA7C957); // Soft highlight green
    final leafPaint = Paint()..color = const Color(0xFF6A994E);

    final pinkPaint = Paint()..color = const Color(0xFFFF85A2);
    final yellowPaint = Paint()..color = const Color(0xFFFFB703);
    final orangePaint = Paint()..color = const Color(0xFFFB8500);
    final centerPaint = Paint()..color = const Color(0xFFFFD166);

    final stemPaint = Paint()
      ..color = const Color(0xFF386641)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // --- LEFT CORNER BUSH ---
    // 1. Dark Green Base Layer
    canvas.drawCircle(Offset(-10, size.height), 95, darkGreenPaint);
    canvas.drawCircle(Offset(55, size.height + 10), 80, darkGreenPaint);
    canvas.drawCircle(Offset(25, size.height - 55), 70, darkGreenPaint);

    // 2. Mid Green Middle Layer
    canvas.drawCircle(Offset(-15, size.height), 80, midGreenPaint);
    canvas.drawCircle(Offset(50, size.height), 70, midGreenPaint);
    canvas.drawCircle(Offset(20, size.height - 45), 60, midGreenPaint);

    // 3. Light Green Top Highlights
    canvas.drawCircle(Offset(-20, size.height), 65, lightGreenPaint);
    canvas.drawCircle(Offset(40, size.height), 55, lightGreenPaint);
    canvas.drawCircle(Offset(15, size.height - 35), 45, lightGreenPaint);

    // 4. Overlapping Leaves peeking out
    canvas.drawOval(Rect.fromCenter(center: Offset(80, size.height - 65), width: 22, height: 12), leafPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(45, size.height - 100), width: 20, height: 10), leafPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(15, size.height - 115), width: 18, height: 9), leafPaint);

    // 5. Stems and Flowers (Left)
    // Stem 1
    final leftStem1 = Path()
      ..moveTo(25, size.height - 85)
      ..quadraticBezierTo(20, size.height - 110, 30, size.height - 130);
    canvas.drawPath(leftStem1, stemPaint);
    
    // Stem 2
    final leftStem2 = Path()
      ..moveTo(65, size.height - 65)
      ..quadraticBezierTo(75, size.height - 80, 80, size.height - 95);
    canvas.drawPath(leftStem2, stemPaint);

    // Draw Flowers
    _drawFlower(canvas, Offset(30, size.height - 130), pinkPaint, centerPaint, 18);
    _drawFlower(canvas, Offset(80, size.height - 95), yellowPaint, orangePaint, 16);
    _drawFlower(canvas, Offset(50, size.height - 55), pinkPaint, centerPaint, 22);


    // --- RIGHT CORNER BUSH ---
    // 1. Dark Green Base Layer
    canvas.drawCircle(Offset(size.width + 10, size.height), 95, darkGreenPaint);
    canvas.drawCircle(Offset(size.width - 55, size.height + 10), 80, darkGreenPaint);
    canvas.drawCircle(Offset(size.width - 25, size.height - 55), 70, darkGreenPaint);

    // 2. Mid Green Middle Layer
    canvas.drawCircle(Offset(size.width + 15, size.height), 80, midGreenPaint);
    canvas.drawCircle(Offset(size.width - 50, size.height), 70, midGreenPaint);
    canvas.drawCircle(Offset(size.width - 15, size.height - 45), 60, midGreenPaint);

    // 3. Light Green Top Highlights
    canvas.drawCircle(Offset(size.width + 20, size.height), 65, lightGreenPaint);
    canvas.drawCircle(Offset(size.width - 40, size.height), 55, lightGreenPaint);
    canvas.drawCircle(Offset(size.width - 10, size.height - 35), 45, lightGreenPaint);

    // 4. Overlapping Leaves peeking out
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width - 80, size.height - 65), width: 22, height: 12), leafPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width - 45, size.height - 100), width: 20, height: 10), leafPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width - 15, size.height - 115), width: 18, height: 9), leafPaint);

    // 5. Stems and Flowers (Right)
    // Stem 1
    final rightStem1 = Path()
      ..moveTo(size.width - 25, size.height - 85)
      ..quadraticBezierTo(size.width - 20, size.height - 110, size.width - 30, size.height - 130);
    canvas.drawPath(rightStem1, stemPaint);
    
    // Stem 2
    final rightStem2 = Path()
      ..moveTo(size.width - 65, size.height - 65)
      ..quadraticBezierTo(size.width - 75, size.height - 80, size.width - 80, size.height - 95);
    canvas.drawPath(rightStem2, stemPaint);

    // Draw Flowers
    _drawFlower(canvas, Offset(size.width - 30, size.height - 130), yellowPaint, orangePaint, 18);
    _drawFlower(canvas, Offset(size.width - 80, size.height - 95), yellowPaint, orangePaint, 20);
    _drawFlower(canvas, Offset(size.width - 50, size.height - 55), yellowPaint, orangePaint, 16);
  }

  void _drawFlower(Canvas canvas, Offset center, Paint petalPaint, Paint centerPaint, double radius) {
    final petalRadius = radius * 0.45;
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72) * 3.14159 / 180;
      final petalCenter = Offset(
        center.dx + radius * 0.55 * math.cos(angle),
        center.dy + radius * 0.55 * math.sin(angle),
      );
      canvas.drawCircle(petalCenter, petalRadius, petalPaint);
    }
    canvas.drawCircle(center, radius * 0.35, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StoryBuddyScreen extends ConsumerStatefulWidget {
  const StoryBuddyScreen({super.key});

  static const String storyText =
      "High up in the sky, there lived a tiny star \nnamed Twinkle. Twinkle was very small — smaller \nthan all the other stars. Every night the big \nstars shone bright, but Twinkle was scared. \nThen a little girl on Earth looked up and said \nMama! That tiny star is the prettiest one! \nTwinkle took a deep breath and shone as bright \nas she could! You were never too small Twinkle — \nyou were just waiting to believe in yourself!";

  @override
  ConsumerState<StoryBuddyScreen> createState() => _StoryBuddyScreenState();
}

class _StoryBuddyScreenState extends ConsumerState<StoryBuddyScreen> {
  int _currentTab = 0; // Tab state: 0 = Story, 1 = Quiz, 2 = Profile

  void _selectTab(int index) {
    setState(() {
      _currentTab = index;
    });

    // Stop any playing audio when switching tabs
    ref.read(audioServiceProvider).stop();

    if (index == 0) {
      ref.read(quizStateProvider.notifier).resetQuiz();
      ref.read(buddyStateProvider.notifier).setIdle();
      ref.read(audioStateProvider.notifier).setIdle();
    } else if (index == 1) {
      ref.read(quizStateProvider.notifier).revealQuiz();
      ref.read(buddyStateProvider.notifier).setPointing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioStateProvider);
    final quizState = ref.watch(quizStateProvider);

    // Dynamic handoff state listener: auto switches tab to Quiz on audio completion
    ref.listen<AudioState>(audioStateProvider, (prev, next) {
      if (next == AudioState.completed) {
        ref.read(quizStateProvider.notifier).revealQuiz();
        ref.read(buddyStateProvider.notifier).setPointing();
        setState(() {
          _currentTab = 1;
        });
      }
    });

    ref.listen<QuizState>(quizStateProvider, (prev, next) {
      if (next.status == QuizStatus.hidden) {
        setState(() {
          _currentTab = 0;
        });
      }
    });

    final String activeBuddyName = _currentTab == 1 ? "with Vidya" : "with Raga";
    final double heroHeight = 380.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE5D5FC), // Soft purple top
              Color(0xFFF9F5FF), // Light lavender center
              Color(0xFFE5D5FC), // Soft purple bottom
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Floral Corner Decorations
            Positioned.fill(
              child: CustomPaint(
                painter: FloralBackgroundPainter(),
              ),
            ),

            // Night Sky Theme Hero Background & Mascot Background with Smooth Fade at the bottom
            if (_currentTab == 0 || _currentTab == 1)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: heroHeight,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [
                        0.0,
                        0.8, // Opaque for top 80%
                        1.0, // Smoothly fades to transparent at the bottom
                      ],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: quizState.status == QuizStatus.completed
                            ? Image.asset(
                                'assets/images/background.png',
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              )
                            : Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF0D0628), // Night sky top
                                      Color(0xFF1A0A4A), // Night sky bottom
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                      ),
                      if (quizState.status != QuizStatus.completed) ...[
                        Positioned.fill(
                          child: TwinklingStars(height: heroHeight),
                        ),
                        Positioned.fill(
                          child: _buildMascotWrapper(
                            child: const BuddyCharacter(),
                            showMusicNotes: _currentTab == 0,
                            height: heroHeight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // 3. Page Content Overlay & Scrollable Card
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Top Bar (Renders on top of the mascot background)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // White Circular Menu Button
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.menu_rounded, color: PebloTheme.primaryPurple, size: 24),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: Colors.black.withOpacity(0.08),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),

                          // Peblo Logo Header
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Peblo",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: PebloTheme.primaryPurple,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.orangeAccent, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    activeBuddyName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF330066),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star_rounded, color: Colors.orangeAccent, size: 14),
                                ],
                              ),
                            ],
                          ),

                          // Right Section: Stars Badge + Speaker Button
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_currentTab == 1) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.orangeAccent, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${quizState.starsEarned}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: PebloTheme.primaryPurple,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              IconButton(
                                onPressed: () {
                                  if (_currentTab == 0) {
                                    final isPlaying = ref.read(audioStateProvider) == AudioState.playing;
                                    if (isPlaying) {
                                      ref.read(audioServiceProvider).stop();
                                    } else {
                                      ref.read(audioServiceProvider).playStory(ref: ref);
                                    }
                                  }
                                },
                                icon: const Icon(Icons.volume_up_rounded, color: PebloTheme.primaryPurple, size: 24),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor: Colors.black.withOpacity(0.08),
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Area
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            // Leave padding at bottom for bottom bar
                            padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 105.0),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: math.max(0.0, constraints.maxHeight - 105.0),
                              ),
                              child: Column(
                                mainAxisAlignment: _currentTab == 2
                                    ? MainAxisAlignment.start
                                    : MainAxisAlignment.end,
                                children: [
                                  // Push the Card down to overlap the mascot header beautifully
                                  if (_currentTab == 0)
                                    const SizedBox(height: 220)
                                  else if (_currentTab == 1)
                                    SizedBox(height: quizState.status == QuizStatus.completed ? 30 : 140),

                                  // Dynamic Page content
                                  if (_currentTab == 0) ...[
                                    const StoryCard(text: StoryBuddyScreen.storyText),
                                  ] else if (_currentTab == 1) ...[
                                    QuizSection(quiz: quizState.questions[quizState.currentQuestionIndex]),
                                  ] else if (_currentTab == 2) ...[
                                    // Profile Mode: includes its own header avatar
                                    const SizedBox(height: 20),
                                    const CircleAvatar(
                                      radius: 64,
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        "🧒",
                                        style: TextStyle(fontSize: 54),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _buildProfileView(),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Floating Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMascotWrapper({
    required Widget child,
    required bool showMusicNotes,
    required double height,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [
                    0.0,
                    0.7, // Keeps the top 70% solid/opaque
                    1.0, // Fades to transparent at the very bottom
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: child,
            ),
          ),
          if (showMusicNotes) ...[
            Positioned(
              left: 30,
              top: 130,
              child: Transform.rotate(
                angle: -0.25,
                child: const Text(
                  "🎵",
                  style: TextStyle(fontSize: 26),
                ),
              ),
            ),
            Positioned(
              right: 40,
              top: 140,
              child: Transform.rotate(
                angle: 0.3,
                child: const Text(
                  "🎶",
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            Positioned(
              left: 60,
              bottom: 80,
              child: const Text(
                "⭐",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ] else ...[
            Positioned(
              left: 60,
              top: height * 0.37,
              child: const Text(
                "⭐",
                style: TextStyle(fontSize: 18),
              ),
            ),
            Positioned(
              right: 60,
              top: height * 0.34,
              child: const Text(
                "⭐",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            children: [
              const Text(
                "Little Explorer",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF330066),
                ),
              ),
              const Text(
                "Level 3 Adventurer",
                style: TextStyle(
                  fontSize: 16,
                  color: PebloTheme.primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFE8DDFC), height: 1),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard(
                    emoji: "🔥",
                    value: "5 Days",
                    label: "Streak",
                    color: Colors.orange,
                  ),
                  _buildStatCard(
                    emoji: "⭐",
                    value: "120",
                    label: "Stars",
                    color: Colors.amber,
                  ),
                  _buildStatCard(
                    emoji: "📖",
                    value: "12",
                    label: "Stories",
                    color: Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Text("🏆", style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Companion Unlocked",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF330066),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "Clever Sparrow Explorer",
                            style: TextStyle(
                              color: PebloTheme.primaryPurple,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required String emoji, required String value, required String label, required Color color}) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 76,
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem(
            index: 0,
            label: "Story",
            icon: Icons.menu_book_rounded,
          ),
          _buildQuizTabItem(),
          _buildTabItem(
            index: 2,
            label: "Profile",
            icon: Icons.person_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizTabItem() {
    final isActive = _currentTab == 1;

    if (isActive) {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -34,
            child: GestureDetector(
              onTap: () => _selectTab(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF8B5CF6),
                          Color(0xFF5B21B6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5B21B6).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          bottom: 1,
                          right: 1,
                          child: Transform.rotate(
                            angle: 0.785,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF08A),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF08A),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "?",
                            style: TextStyle(
                              color: Color(0xFF5B21B6),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Quiz",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFEF08A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 70),
        ],
      );
    } else {
      return _buildTabItem(
        index: 1,
        label: "Quiz",
        icon: Icons.help_outline_rounded,
      );
    }
  }

  Widget _buildTabItem({required int index, required String label, required IconData icon}) {
    final isActive = _currentTab == index;
    return InkWell(
      onTap: () => _selectTab(index),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? PebloTheme.primaryPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : PebloTheme.primaryPurple.withOpacity(0.65),
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? PebloTheme.primaryPurple : PebloTheme.primaryPurple.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Night sky twinkling stars decoration classes
class TwinklingStars extends StatefulWidget {
  final double height;
  const TwinklingStars({super.key, required this.height});

  @override
  State<TwinklingStars> createState() => _TwinklingStarsState();
}

class _TwinklingStarsState extends State<TwinklingStars> {
  final List<StarData> _stars = [];

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    for (int i = 0; i < 15; i++) {
      _stars.add(StarData(
        x: random.nextDouble(),
        y: random.nextDouble() * 0.75, // Keep stars in top 75% of the hero section
        size: 3.0 + random.nextDouble() * 1.5,
        duration: 1 + random.nextInt(3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ..._stars.map((star) => Positioned(
              left: star.x * MediaQuery.of(context).size.width,
              top: star.y * widget.height,
              child: TwinklingStarWidget(star: star),
            )),
        Positioned(
          left: MediaQuery.of(context).size.width * 0.5 - 90,
          top: widget.height * 0.26,
          child: const GlowingStarWidget(),
        ),
      ],
    );
  }
}

class StarData {
  final double x;
  final double y;
  final double size;
  final int duration;

  StarData({
    required this.x,
    required this.y,
    required this.size,
    required this.duration,
  });
}

class TwinklingStarWidget extends StatefulWidget {
  final StarData star;
  const TwinklingStarWidget({super.key, required this.star});

  @override
  State<TwinklingStarWidget> createState() => _TwinklingStarWidgetState();
}

class _TwinklingStarWidgetState extends State<TwinklingStarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.star.duration),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        width: widget.star.size,
        height: widget.star.size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class GlowingStarWidget extends StatefulWidget {
  const GlowingStarWidget({super.key});

  @override
  State<GlowingStarWidget> createState() => _GlowingStarWidgetState();
}

class _GlowingStarWidgetState extends State<GlowingStarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.25).animate(
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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 10,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
