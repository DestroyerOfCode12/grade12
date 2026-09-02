import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/lesson.dart';
import '../demo_content/demo_catalogue.dart';

abstract class LessonRepository {
  Future<Lesson?> fetchLesson(String lessonId);
}

class SupabaseLessonRepository implements LessonRepository {
  final SupabaseClient client;
  SupabaseLessonRepository(this.client);

  @override
  Future<Lesson?> fetchLesson(String lessonId) async {
    final lessonRow = await client
        .from('lessons')
        .select()
        .eq('id', lessonId)
        .maybeSingle();
    if (lessonRow == null) return null;

    final blockRows = await client
        .from('lesson_blocks')
        .select()
        .eq('lesson_id', lessonId)
        .order('sort_order');

    final blocks = (blockRows as List)
        .map((b) => LessonBlock.fromMap(b as Map<String, dynamic>))
        .toList();
    return Lesson.fromMap(lessonRow, blocks);
  }
}

class LocalSeedLessonRepository implements LessonRepository {
  @override
  Future<Lesson?> fetchLesson(String lessonId) async {
    if (lessonId == DemoCatalogue.linearFunctionsLessonId) {
      return DemoCatalogue.linearFunctionsLesson();
    }
    return null;
  }
}
