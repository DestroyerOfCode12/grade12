import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/question.dart';
import '../demo_content/demo_catalogue.dart';
import 'quiz_repository.dart';

/// Section 9: "Run a short diagnostic assessment for each selected subject." One topic's worth of
/// diagnostic questions — the assessment screen runs one of these per topic that has one
/// available, skipping topics that don't (most of the catalogue right now — see
/// docs/CONTINUATION.md).
class DiagnosticTopicQuiz {
  final String subjectId;
  final String subjectName;
  final String topicId;
  final String topicTitle;
  final String quizId;
  final List<Question> questions;

  const DiagnosticTopicQuiz({
    required this.subjectId,
    required this.subjectName,
    required this.topicId,
    required this.topicTitle,
    required this.quizId,
    required this.questions,
  });
}

abstract class DiagnosticRepository {
  Future<List<DiagnosticTopicQuiz>> fetchAvailable(
    Set<String> selectedSubjectIds,
  );
}

class SupabaseDiagnosticRepository implements DiagnosticRepository {
  final SupabaseClient client;
  final QuizRepository quizRepository;
  SupabaseDiagnosticRepository(this.client, this.quizRepository);

  @override
  Future<List<DiagnosticTopicQuiz>> fetchAvailable(
    Set<String> selectedSubjectIds,
  ) async {
    if (selectedSubjectIds.isEmpty) return const [];

    final rows = await client
        .from('quizzes')
        .select(
          'id, topic_id, topics!inner(id, title, subject_id, subjects(id, name))',
        )
        .eq('quiz_kind', 'diagnostic')
        .eq('content_status', 'published')
        .inFilter('topics.subject_id', selectedSubjectIds.toList());

    final result = <DiagnosticTopicQuiz>[];
    for (final row in (rows as List)) {
      // `!inner` guarantees a matching topics row exists for every quiz row returned here.
      final topic = row['topics'] as Map<String, dynamic>;
      final subject = topic['subjects'] as Map<String, dynamic>?;
      final questions = await quizRepository.fetchQuizQuestions(
        row['id'] as String,
      );
      if (questions.isEmpty) continue;

      result.add(
        DiagnosticTopicQuiz(
          subjectId: topic['subject_id'] as String,
          subjectName: subject?['name'] as String? ?? 'Subject',
          topicId: topic['id'] as String,
          topicTitle: topic['title'] as String,
          quizId: row['id'] as String,
          questions: questions,
        ),
      );
    }
    return result;
  }
}

/// Local dev mode / guest mode: only the embedded demo Mathematics topic has a diagnostic set,
/// reusing the same demo questions the checkpoint quiz uses — this is clearly-labelled demo
/// content either way (section 2), so one small question bank serving two purposes is an honest
/// simplification, not a hidden shortcut.
class LocalDiagnosticRepository implements DiagnosticRepository {
  @override
  Future<List<DiagnosticTopicQuiz>> fetchAvailable(
    Set<String> selectedSubjectIds,
  ) async {
    if (!selectedSubjectIds.contains(DemoCatalogue.mathematicsSubjectId)) {
      return const [];
    }
    return [
      DiagnosticTopicQuiz(
        subjectId: DemoCatalogue.mathematicsSubjectId,
        subjectName: 'Mathematics',
        topicId: DemoCatalogue.functionsTopicId,
        topicTitle: DemoCatalogue.functionsTopicTitle,
        quizId: DemoCatalogue.checkpointQuizId,
        questions: DemoCatalogue.checkpointQuestions(),
      ),
    ];
  }
}
