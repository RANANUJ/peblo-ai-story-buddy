import 'dart:convert';
import '../models/quiz_model.dart';

class QuizRepository {
  Future<QuizModel> fetchQuiz() async {
    // Standard static JSON payload contract (PRD Section 7.1 & Section 9.3 hint support)
    const jsonString = '''
    {
      "question": "What colour was Pip the Robot's lost gear?",
      "options": ["Red", "Green", "Blue", "Yellow"],
      "answer": "Blue",
      "hint": "Think about what colour the sky is!"
    }
    ''';
    
    // Simulate minor network delay for realistic loading representation
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return QuizModel.fromJson(jsonMap);
    } catch (e) {
      throw FormatException("Malformed quiz JSON data: $e");
    }
  }
}
