class QuizModel {
  final int id;
  final String question;
  final List<String> options;
  final String answer;
  final String hint;

  const QuizModel({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    required this.hint,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final options = List<String>.from(json['options'] ?? []);
    assert(
      options.length >= 3 && options.length <= 5,
      'Quiz must have 3 to 5 options'
    );
    return QuizModel(
      id: json['id'] as int,
      question: json['question'] as String,
      options: options,
      answer: json['answer'] as String,
      hint: json['hint'] as String,
    );
  }
}
