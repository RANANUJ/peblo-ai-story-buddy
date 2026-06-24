import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/peblo_theme.dart';

class OptionTile extends StatefulWidget {
  final String text;
  final String letter;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  const OptionTile({
    super.key,
    required this.text,
    required this.letter,
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
    if (widget.isWrong && !oldWidget.isWrong) {
      _triggerFailureEffects();
    }
  }

  void _triggerFailureEffects() {
    _shakeController.forward(from: 0.0);
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.white;
    Color borderColor = const Color(0xFFE8DDFC); // Soft lavender border
    double borderWidth = 2.0;
    Color textColor = const Color(0xFF330066); // Deep purple text for mockup alignment
    Color badgeBgColor = PebloTheme.primaryPurple;
    Color badgeTextColor = Colors.white;
    List<BoxShadow>? shadows;

    if (widget.isCorrect) {
      backgroundColor = PebloTheme.successGreen;
      borderColor = PebloTheme.successGreen;
      textColor = Colors.white;
      badgeBgColor = Colors.white;
      badgeTextColor = PebloTheme.successGreen;
      shadows = [
        BoxShadow(
          color: PebloTheme.successGreen.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        )
      ];
    } else if (widget.isWrong) {
      backgroundColor = PebloTheme.errorRed.withOpacity(0.05);
      borderColor = PebloTheme.errorRed;
      borderWidth = 2.0;
      textColor = PebloTheme.errorRed;
      badgeBgColor = PebloTheme.errorRed;
      badgeTextColor = Colors.white;
    } else if (widget.isSelected) {
      backgroundColor = PebloTheme.optionSelectedBg;
      borderColor = PebloTheme.optionSelectedBorder;
      borderWidth = 2.0;
      textColor = const Color(0xFF330066);
      badgeBgColor = PebloTheme.primaryPurple;
      badgeTextColor = Colors.white;
      shadows = [
        BoxShadow(
          color: PebloTheme.primaryPurple.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 3),
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
              label: 'Option ${widget.letter}: ${widget.text}',
              child: InkWell(
                onTap: (widget.isCorrect || widget.isWrong) ? null : widget.onTap,
                borderRadius: BorderRadius.circular(20.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  constraints: const BoxConstraints(minHeight: 40.0),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: borderColor,
                      width: borderWidth,
                    ),
                    boxShadow: shadows,
                  ),
                  child: Row(
                    children: [
                      // Circular Letter Badge (A, B, C, D)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.letter,
                          style: TextStyle(
                            color: badgeTextColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Option Text
                      Expanded(
                        child: Text(
                          widget.text,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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
