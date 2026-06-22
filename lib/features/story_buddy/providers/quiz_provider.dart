import 'package:flutter_riverpod/flutter_riverpod.dart';

enum QuizStatus { hidden, revealing, awaitingAnswer, wrong, correct }

class QuizState {
  final QuizStatus status;
  final String? selectedOption;
  final int wrongAttempts;

  const QuizState({
    required this.status,
    this.selectedOption,
    this.wrongAttempts = 0,
  });

  QuizState copyWith({
    QuizStatus? status,
    String? selectedOption,
    int? wrongAttempts,
  }) {
    return QuizState(
      status: status ?? this.status,
      selectedOption: selectedOption ?? this.selectedOption,
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
    );
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier() : super(const QuizState(status: QuizStatus.hidden));

  void hideQuiz() => state = const QuizState(status: QuizStatus.hidden);
  
  void revealQuiz() {
    state = state.copyWith(status: QuizStatus.revealing);
  }

  void setAwaitingAnswer() {
    state = state.copyWith(status: QuizStatus.awaitingAnswer);
  }
  
  void selectOption(String option) {
    state = state.copyWith(selectedOption: option);
  }

  void setWrong() {
    state = state.copyWith(
      status: QuizStatus.wrong,
      wrongAttempts: state.wrongAttempts + 1,
    );
  }

  void setCorrect() {
    state = state.copyWith(status: QuizStatus.correct);
  }
  
  void resetWrongAttempts() {
    state = state.copyWith(wrongAttempts: 0);
  }

  void resetQuiz() {
    state = const QuizState(status: QuizStatus.hidden);
  }
}

final quizStateProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier();
});
