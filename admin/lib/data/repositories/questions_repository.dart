import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/question_models.dart';

/// Section 12: "Create and edit questions" / "Create quizzes and game challenges".
class QuestionsRepository {
  final SupabaseClient client;
  QuestionsRepository(this.client);

  Future<List<AdminQuestion>> fetchForTopic(String topicId) async {
    final rows = await client
        .from('questions')
        .select()
        .eq('topic_id', topicId)
        .order('created_at');
    return (rows as List)
        .map((r) => AdminQuestion.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<AdminQuestion> fetchOne(String questionId) async {
    final row = await client
        .from('questions')
        .select()
        .eq('id', questionId)
        .single();
    return AdminQuestion.fromMap(row);
  }

  Future<String> createQuestion({
    required String topicId,
    required String kind,
    required String promptMarkdown,
    required int difficulty,
    required num marks,
  }) async {
    final row = await client
        .from('questions')
        .insert({
          'topic_id': topicId,
          'kind': kind,
          'prompt_markdown': promptMarkdown,
          'difficulty': difficulty,
          'marks': marks,
          'content_status': 'draft',
          'verification_status': 'unverified',
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> updateStatus(
    String questionId, {
    String? contentStatus,
    String? verificationStatus,
  }) async {
    final patch = <String, dynamic>{};
    if (contentStatus != null) {
      patch['content_status'] = contentStatus;
    }
    if (verificationStatus != null) {
      patch['verification_status'] = verificationStatus;
    }
    if (patch.isEmpty) {
      return;
    }
    await client.from('questions').update(patch).eq('id', questionId);
  }

  Future<List<AdminQuestionOption>> fetchOptions(String questionId) async {
    final rows = await client
        .from('question_options')
        .select()
        .eq('question_id', questionId)
        .order('sort_order');
    return (rows as List)
        .map((r) => AdminQuestionOption.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> addOption({
    required String questionId,
    required String label,
    required String bodyMarkdown,
    required bool isCorrect,
    required int sortOrder,
  }) async {
    await client.from('question_options').insert({
      'question_id': questionId,
      'label': label,
      'body_markdown': bodyMarkdown,
      'is_correct': isCorrect,
      'sort_order': sortOrder,
    });
  }

  Future<void> deleteOption(String optionId) async {
    await client.from('question_options').delete().eq('id', optionId);
  }

  Future<void> setSolution({
    required String questionId,
    required String solutionMarkdown,
    required bool isOfficialMemorandum,
    String? explanationMarkdown,
  }) async {
    await client.from('question_solutions').insert({
      'question_id': questionId,
      'solution_markdown': solutionMarkdown,
      'is_official_memorandum': isOfficialMemorandum,
      'explanation_markdown': explanationMarkdown,
    });
  }

  // --- Quizzes ---

  Future<List<AdminQuiz>> fetchQuizzesForTopic(String topicId) async {
    final rows = await client.from('quizzes').select().eq('topic_id', topicId);
    return (rows as List)
        .map((r) => AdminQuiz.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<String> createQuiz({
    required String topicId,
    required String title,
    required String quizKind,
  }) async {
    final row = await client
        .from('quizzes')
        .insert({
          'topic_id': topicId,
          'title': title,
          'quiz_kind': quizKind,
          'content_status': 'draft',
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> addQuestionToQuiz(
    String quizId,
    String questionId,
    int sortOrder,
  ) async {
    await client.from('quiz_questions').insert({
      'quiz_id': quizId,
      'question_id': questionId,
      'sort_order': sortOrder,
    });
  }

  Future<void> updateQuizStatus(String quizId, String contentStatus) async {
    await client
        .from('quizzes')
        .update({'content_status': contentStatus})
        .eq('id', quizId);
  }
}
