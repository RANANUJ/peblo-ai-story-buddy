import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/audio_provider.dart';
import '../../../../core/theme/peblo_theme.dart';

class ReadButton extends ConsumerStatefulWidget {
  final VoidCallback onTap;

  const ReadButton({
    super.key,
    required this.onTap,
  });

  @override
  ConsumerState<ReadButton> createState() => _ReadButtonState();
}

class _ReadButtonState extends ConsumerState<ReadButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
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

    if (audioState == AudioState.idle) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }

    switch (audioState) {
      case AudioState.idle:
        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: ElevatedButton(
                onPressed: widget.onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PebloTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: PebloTheme.primaryPurple.withOpacity(0.3),
                  minimumSize: const Size(240, PebloTheme.minTouchTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PebloTheme.borderRadius),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 28),
                    SizedBox(width: 8),
                    Text(
                      "Read Me a Story!",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

      case AudioState.preparing:
        return ElevatedButton(
          onPressed: null, // Disabled in preparing state
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.black54,
            minimumSize: const Size(240, PebloTheme.minTouchTarget),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PebloTheme.borderRadius),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(PebloTheme.primaryPurple),
                ),
              ),
              SizedBox(width: 12),
              Text(
                "Getting ready...",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        );

      case AudioState.playing:
        return ElevatedButton(
          onPressed: null, // Disabled in playing state
          style: ElevatedButton.styleFrom(
            backgroundColor: PebloTheme.primaryPurple.withOpacity(0.1),
            disabledBackgroundColor: PebloTheme.primaryPurple.withOpacity(0.1),
            disabledForegroundColor: PebloTheme.primaryPurple,
            minimumSize: const Size(240, PebloTheme.minTouchTarget),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PebloTheme.borderRadius),
              side: const BorderSide(color: PebloTheme.primaryPurple, width: 2),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.volume_up_rounded, size: 24),
              SizedBox(width: 8),
              Text(
                "Listening...",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: PebloTheme.primaryPurple,
                ),
              ),
            ],
          ),
        );

      case AudioState.completed:
      case AudioState.error:
        // Section 6.3 - Hidden during completed or error states (reveals quiz or error retry card instead)
        return const SizedBox.shrink();
    }
  }
}
