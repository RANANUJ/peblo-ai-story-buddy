import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/audio_provider.dart';
import '../../../../core/theme/peblo_theme.dart';

class StoryCard extends ConsumerStatefulWidget {
  final String text;

  const StoryCard({
    super.key,
    this.text = "Once upon a time, a clever little robot named Pip lost his shiny blue gear in the Whispering Woods...",
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
    // Pulsing offset shadow/border width animation
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
            borderRadius: BorderRadius.circular(PebloTheme.borderRadius),
            boxShadow: isPlaying
                ? [
                    BoxShadow(
                      color: PebloTheme.primaryPurple.withOpacity(0.15),
                      blurRadius: _glowAnimation.value * 3,
                      spreadRadius: _glowAnimation.value * 0.5,
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0, // Driven by custom shadow container
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PebloTheme.borderRadius),
              side: BorderSide(
                color: isPlaying
                    ? PebloTheme.primaryPurple.withOpacity(0.8)
                    : Colors.grey.shade200,
                width: isPlaying ? _glowAnimation.value : 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: SingleChildScrollView(
                child: Text(
                  widget.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        height: 1.6,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
