import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/peblo_theme.dart';

class OptionTile extends StatefulWidget {
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  const OptionTile({
    super.key,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
  });

  @override
  State<OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<OptionTile> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Oscillating offset for the shake animation (PRD Section 7.4)
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    if (widget.isWrong) {
      _triggerFailureEffects();
    }
  }

  @override
  void didUpdateWidget(covariant OptionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger effects only on new failure transition
    if (widget.isWrong && !oldWidget.isWrong) {
      _triggerFailureEffects();
    }
  }

  void _triggerFailureEffects() {
    _shakeController.forward(from: 0.0);
    HapticFeedback.mediumImpact(); // P0 Requirement
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine background, border, text color, and shadow based on validation states
    Color backgroundColor = Colors.white;
    Color borderColor = PebloTheme.primaryPurple;
    double borderWidth = 1.5;
    Color textColor = Colors.black87;
    List<BoxShadow>? shadows;

    if (widget.isCorrect) {
      backgroundColor = PebloTheme.successGreen;
      borderColor = PebloTheme.successGreen;
      textColor = Colors.white;
      shadows = [
        BoxShadow(
          color: PebloTheme.successGreen.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        )
      ];
    } else if (widget.isWrong) {
      borderColor = PebloTheme.errorRed;
      borderWidth = 2.5;
      textColor = PebloTheme.errorRed;
    } else if (widget.isSelected) {
      backgroundColor = PebloTheme.primaryPurple.withOpacity(0.05);
      borderWidth = 3.0;
      shadows = [
        BoxShadow(
          color: PebloTheme.primaryPurple.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        )
      ];
    }

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0.0),
          child: Material(
            color: Colors.transparent,
            child: Semantics(
              button: true,
              enabled: !(widget.isCorrect || widget.isWrong),
              selected: widget.isSelected,
              label: 'Option: ${widget.text}',
              hint: widget.isCorrect
                  ? 'Correct answer selected'
                  : widget.isWrong
                      ? 'Incorrect answer selected'
                      : 'Double tap to select this answer',
              child: InkWell(
                onTap: (widget.isCorrect || widget.isWrong) ? null : widget.onTap,
                borderRadius: BorderRadius.circular(PebloTheme.borderRadius),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  constraints: const BoxConstraints(minHeight: PebloTheme.minTouchTarget), // Min 56dp (Section 5.1/7.4)
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(PebloTheme.borderRadius),
                    border: Border.all(
                      color: borderColor,
                      width: borderWidth,
                    ),
                    boxShadow: shadows,
                  ),
                  child: Center(
                    child: Text(
                      widget.text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
