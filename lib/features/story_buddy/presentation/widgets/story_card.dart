import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/audio_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../../../core/theme/peblo_theme.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/constants/buddy_assets.dart';

const List<String> storyParts = [
  // PART 1
  "High up in the sky... ✨\n\n"
  "There lived a tiny star\n"
  "named Twinkle. 🌟",

  // PART 2
  "Twinkle was very small —\n"
  "smaller than all\n"
  "the other stars. 🌙\n\n"
  "Every night the big stars\n"
  "shone bright...\n"
  "but Twinkle was scared. 😟",

  // PART 3
  "Then a little girl on Earth\n"
  "looked up and said —\n\n"
  "\"Mama! That tiny star...\n"
  "is the prettiest one!\" 💫",

  // PART 4
  "Twinkle took a deep breath...\n"
  "and shone as bright\n"
  "as she could! 🌟\n\n"
  "You were never too small —\n"
  "you were just waiting to\n"
  "believe in yourself! ⭐",
];

class StoryCard extends ConsumerStatefulWidget {
  final String text;
  final String title;

  const StoryCard({
    super.key,
    required this.text,
    this.title = "The Little Star Who Was Scared of the Dark",
  });

  @override
  ConsumerState<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends ConsumerState<StoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 1.5, end: 4.5).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioStateProvider);
    final isPlaying = audioState == AudioState.playing;

    if (isPlaying) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Title Row with Book Emoji
                  const Row(
                    children: [
                      Text("📖", style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "The Little Star Who Was Scared of the Dark",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFD700), // Golden title
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. Fixed-height story text container with vertical scrolling
                  Container(
                    height: 160, // FIXED — never changes
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE8DEFF),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: RawScrollbar(
                      thumbColor: PebloTheme.primaryPurple.withOpacity(0.35),
                      radius: const Radius.circular(4),
                      thickness: 4.0,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Text(
                            widget.text,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: Color(0xFF2D1B5C),
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Orange Gradient Read Button
                  Center(
                    child: _buildReadButton(audioState),
                  ),
                  const SizedBox(height: 10),

                  // 5. Dynamic Mascot Subtitle Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage(RagaAssets.idle),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                            children: [
                              TextSpan(
                                text: "Raga",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: PebloTheme.primaryPurple,
                                ),
                              ),
                              TextSpan(text: " will read this story out loud for you!"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadButton(AudioState audioState) {
    if (audioState == AudioState.preparing) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(PebloTheme.primaryPurple),
              ),
            ),
            SizedBox(width: 10),
            Text(
              "Preparing voice...",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final isPlaying = audioState == AudioState.playing;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF9E00), // Vibrant orange
            Color(0xFFFF6D00), // Deep orange
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6D00).withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isPlaying) {
              ref.read(audioServiceProvider).stop();
            } else {
              ref.read(audioServiceProvider).playStory(ref: ref);
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: const Color(0xFFFF6D00),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isPlaying ? "Stop Story" : "Read Me a Story",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
