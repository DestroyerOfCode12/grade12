import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/question.dart';
import '../demo_content/demo_catalogue.dart';

abstract class QuizRepository {
  Future<List<Question>> fetchQuizQuestions(String quizId);
}

class SupabaseQuizRepository implements QuizRepository {
  final SupabaseClient client;
  SupabaseQuizRepository(this.client);

  @override
  Future<List<Question>> fetchQuizQuestions(String quizId) async {
    final quizQuestionRows = await client
        .from('quiz_questions')
        .select('question_id, sort_order, questions(*, question_options(*))')
        .eq('quiz_id', quizId)
        .order('sort_order');

    return (quizQuestionRows as List).map((row) {
      final q = row['questions'] as Map<String, dynamic>;
      final options = (q['question_options'] as List? ?? [])
          .map((o) => QuestionOption.fromMap(o as Map<String, dynamic>))
          .toList();
      return Question.fromMap(q, options: options);
    }).toList();
  }
}

class LocalSeedQuizRepository implements QuizRepository {
  @override
  Future<List<Question>> fetchQuizQuestions(String quizId) async {
    if (quizId == DemoCatalogue.checkpointQuizId) {
      return DemoCatalogue.checkpointQuestions();
    }
    return [];
  }
}
