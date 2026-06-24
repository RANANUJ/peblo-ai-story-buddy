import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/quiz_model.dart';
import '../../../core/services/tts_service.dart';

enum QuizStatus { hidden, revealing, awaitingAnswer, wrong, correct, completed }

class QuizState {
  final QuizStatus status;
  final String? selectedOption;
  final int wrongAttempts;
  final int currentQuestionIndex;
  final int starsEarned;
  final int firstTryCorrectCount;
  final List<QuizModel> questions;

  const QuizState({
    required this.status,
    this.selectedOption,
    this.wrongAttempts = 0,
    this.currentQuestionIndex = 0,
    this.starsEarned = 0,
    this.firstTryCorrectCount = 0,
    required this.questions,
  });

  QuizState copyWith({
    QuizStatus? status,
    String? selectedOption,
    int? wrongAttempts,
    int? currentQuestionIndex,
    int? starsEarned,
    int? firstTryCorrectCount,
    List<QuizModel>? questions,
  }) {
    return QuizState(
      status: status ?? this.status,
      selectedOption: selectedOption ?? this.selectedOption,
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      starsEarned: starsEarned ?? this.starsEarned,
      firstTryCorrectCount: firstTryCorrectCount ?? this.firstTryCorrectCount,
      questions: questions ?? this.questions,
    );
  }
}

const List<QuizModel> defaultQuestions = [
  QuizModel(
    id: 1,
    question: "What was the tiny star's name?",
    options: ["Sparkle", "Twinkle", "Shiny", "Blinky"],
    answer: "Twinkle",
    hint: "The name sounds like a nursery rhyme!",
  ),
  QuizModel(
    id: 2,
    question: "Why was Twinkle scared every night?",
    options: [
      "A cloud was chasing her",
      "It was too cold in the sky",
      "Nobody would see her tiny light",
      "She lost her friends"
    ],
    answer: "Nobody would see her tiny light",
    hint: "Twinkle thought she was too small!",
  ),
  QuizModel(
    id: 3,
    question: "Who said Twinkle was the prettiest star?",
    options: [
      "The big stars",
      "The moon",
      "Her mama star",
      "A little girl on Earth"
    ],
    answer: "A little girl on Earth",
    hint: "Someone looking up from down below!",
  ),
  QuizModel(
    id: 4,
    question: "What did Twinkle do after feeling warm inside?",
    options: [
      "She hid behind a cloud",
      "She fell asleep",
      "She shone as bright as she could",
      "She ran away from the sky"
    ],
    answer: "She shone as bright as she could",
    hint: "Twinkle took a deep breath and was brave!",
  ),
  QuizModel(
    id: 5,
    question: "What did the big stars say to Twinkle?",
    options: [
      "You are too small for us!",
      "Go away little star!",
      "You were just waiting to believe in yourself!",
      "Come back when you are bigger!"
    ],
    answer: "You were just waiting to believe in yourself!",
    hint: "The big stars said something very kind!",
  ),
];

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier()
      : super(const QuizState(
          status: QuizStatus.hidden,
          questions: defaultQuestions,
        ));

  void hideQuiz() => state = state.copyWith(status: QuizStatus.hidden);

  void revealQuiz() {
    state = state.copyWith(status: QuizStatus.revealing);
  }

  void setAwaitingAnswer() {
    state = state.copyWith(status: QuizStatus.awaitingAnswer, selectedOption: null);
  }

  Future<void> handleAnswer({
    required String selectedOption,
    required AudioService audioService,
    required WidgetRef ref,
  }) async {
    final currentQuestion = state.questions[state.currentQuestionIndex];
    final isCorrect = selectedOption == currentQuestion.answer;

    if (isCorrect) {
      final gotRightOnFirstTry = state.wrongAttempts == 0;

      // Update state to correct after 300ms delay to show checkmark, Vidya celebrating, and confetti
      Future.delayed(const Duration(milliseconds: 300), () {
        state = state.copyWith(
          status: QuizStatus.correct,
          selectedOption: selectedOption,
        );
      });

      // Play correct tune and WAIT for it
      await audioService.playCorrect();

      // Update stars and first try correct counts
      final totalStarsEarned = state.starsEarned + 1;
      final newFirstTryCorrectCount = state.firstTryCorrectCount + (gotRightOnFirstTry ? 1 : 0);

      // Check if more questions or final
      if (state.currentQuestionIndex < 4) {
        // Wait 400ms after audio finishes before moving to next question
        await Future.delayed(const Duration(milliseconds: 400));
        
        state = state.copyWith(
          status: QuizStatus.awaitingAnswer,
          selectedOption: null,
          currentQuestionIndex: state.currentQuestionIndex + 1,
          wrongAttempts: 0,
          starsEarned: totalStarsEarned,
          firstTryCorrectCount: newFirstTryCorrectCount,
        );
        // Auto play next question audio
        await audioService.playQuestion(state.currentQuestionIndex);
      } else {
        // All 5 done — show final screen
        await Future.delayed(const Duration(milliseconds: 400));
        
        state = state.copyWith(
          status: QuizStatus.completed,
          starsEarned: totalStarsEarned,
          firstTryCorrectCount: newFirstTryCorrectCount,
        );
      }
    } else {
      // Wrong answer
      state = state.copyWith(
        status: QuizStatus.wrong,
        selectedOption: selectedOption,
        wrongAttempts: state.wrongAttempts + 1,
      );

      // Play wrong tune and WAIT for it
      await audioService.playWrong();

      // Reset to awaiting — STAY same question
      state = state.copyWith(
        status: QuizStatus.awaitingAnswer,
        selectedOption: null,
      );
    }
  }

  void resetQuiz() {
    state = const QuizState(
      status: QuizStatus.hidden,
      currentQuestionIndex: 0,
      starsEarned: 0,
      firstTryCorrectCount: 0,
      questions: defaultQuestions,
    );
  }
}

final quizStateProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier();
});

class StoryPartNotifier extends StateNotifier<int> {
  StoryPartNotifier() : super(0);

  void setPartIndex(int index) {
    if (state != index) {
      state = index;
    }
  }

  void reset() => state = 0;
}

final storyPartProvider = StateNotifierProvider<StoryPartNotifier, int>((ref) {
  return StoryPartNotifier();
});
