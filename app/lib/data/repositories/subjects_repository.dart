import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/subject.dart';
import '../demo_content/demo_catalogue.dart';

/// Behind this interface: a real Supabase-backed catalogue when configured, or the embedded
/// demo catalogue in local dev mode / when offline. Screens never know which one they got —
/// the "Demo content" badge is driven by each model's own flags, not by which repository served
/// it, so the same UI code is correct in both cases.
abstract class SubjectsRepository {
  Future<List<Subject>> fetchCatalogue();
}

class SupabaseSubjectsRepository implements SubjectsRepository {
  final SupabaseClient client;
  SupabaseSubjectsRepository(this.client);

  @override
  Future<List<Subject>> fetchCatalogue() async {
    final rows = await client
        .from('subjects')
        .select()
        .eq('content_status', 'published')
        .order('sort_order');
    return (rows as List)
        .map((r) => Subject.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}

/// Falls back to the full draft catalogue too (not just published) because in local dev / offline
/// mode there is no admin workflow to publish anything — the whole point is to see something.
class LocalSeedSubjectsRepository implements SubjectsRepository {
  @override
  Future<List<Subject>> fetchCatalogue() async => DemoCatalogue.subjects();
}
