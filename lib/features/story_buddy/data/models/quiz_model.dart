class QuizModel {
  final String question;
  final List<String> options; // 3, 4, or 5 items
  final String answer;
  final String? hint; // Optional field for Whisper Hint Mode

  const QuizModel({
    required this.question,
    required this.options,
    required this.answer,
    this.hint,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final optionsList = List<String>.from(json['options'] ?? []);

    // Safety guard — PRD specifies 3 to 5 options only
    assert(
      optionsList.length >= 3 && optionsList.length <= 5,
      'Quiz must have between 3 and 5 options',
    );

    return QuizModel(
      question: json['question'] as String,
      options: optionsList,
      answer: json['answer'] as String,
      hint: json['hint'] as String?,
    );
  }
}
