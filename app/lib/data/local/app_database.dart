import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Local mirror of a subset of the Postgres schema (docs/DATA_MODEL.md), enough for the app's
/// core loop — lessons, quizzes, and attempts — to work with zero connectivity (section 10).
///
/// Implementation note: this is hand-written `package:sqlite3` access rather than Drift.
/// Drift's `build_runner`/`drift_dev` codegen currently crashes analyzing this Flutter SDK
/// version (Dart 3.13.2 uses a syntax feature no analyzer version compatible with
/// `build_resolvers` can serialize yet — an upstream ecosystem gap, tracked in
/// docs/CONTINUATION.md, not something this codebase can work around by editing app code).
/// Section 3 explicitly allows "Drift or an equally reliable SQLite-based solution" — this is
/// that substitution. Swapping back to Drift later is a data-layer-only change; no repository
/// or UI code above [AppDatabase] needs to know which one is in use.
class AppDatabase {
  final Database _db;

  AppDatabase._(this._db) {
    _createSchema();
  }

  /// Opens (or creates) the on-device database file in the app's documents directory.
  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'matricquest_sa.sqlite'));
    return AppDatabase._(sqlite3.open(file.path));
  }

  /// In-memory database for unit/widget tests — fully isolated per test, no file system access.
  factory AppDatabase.forTesting() => AppDatabase._(sqlite3.openInMemory());

  void _createSchema() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS local_subjects (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        papers_available INTEGER NOT NULL DEFAULT 0,
        lessons_in_review INTEGER NOT NULL DEFAULT 0,
        full_course_available INTEGER NOT NULL DEFAULT 0,
        is_selected_by_learner INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS local_lessons (
        id TEXT PRIMARY KEY,
        topic_id TEXT NOT NULL,
        subject_id TEXT NOT NULL,
        title TEXT NOT NULL,
        blocks_json TEXT NOT NULL,
        is_seed_demo_content INTEGER NOT NULL DEFAULT 0,
        downloaded INTEGER NOT NULL DEFAULT 1
      );

      CREATE TABLE IF NOT EXISTS local_quizzes (
        id TEXT PRIMARY KEY,
        topic_id TEXT NOT NULL,
        title TEXT NOT NULL,
        questions_json TEXT NOT NULL
      );

      -- Outbox of not-yet-synced writes. Each row's primary key IS the idempotency key that was
      -- generated when the learner started the action, so replaying this table after
      -- reconnecting can never double-submit (section 10 "conflict-safe progress merging";
      -- section 13 idempotency).
      CREATE TABLE IF NOT EXISTS outbox_entries (
        id TEXT PRIMARY KEY,
        kind TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        sync_attempts INTEGER NOT NULL DEFAULT 0
      );

      -- Local-only learner state for Guest Mode, and a fast on-device cache for signed-in
      -- learners. The authoritative XP total for a signed-in learner lives server-side in
      -- xp_events (docs/DATA_MODEL.md); this table is a display cache, not a source of truth.
      CREATE TABLE IF NOT EXISTS local_learner_state (
        profile_id TEXT PRIMARY KEY,
        total_xp INTEGER NOT NULL DEFAULT 0,
        current_streak_days INTEGER NOT NULL DEFAULT 0,
        longest_streak_days INTEGER NOT NULL DEFAULT 0,
        last_active_local_date TEXT,
        freeze_tokens INTEGER NOT NULL DEFAULT 0
      );

      -- Guest-mode / offline mirror of study_plans + study_sessions (section 9/11, screen 20).
      -- One row per profile marks which generated plan is "active"; regenerating replaces every
      -- not-yet-completed session for that profile rather than accumulating stale plans, so a
      -- learner never sees two conflicting schedules.
      CREATE TABLE IF NOT EXISTS local_study_sessions (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        subject_id TEXT NOT NULL,
        topic_id TEXT NOT NULL,
        topic_title TEXT NOT NULL,
        scheduled_for TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL,
        session_kind TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'scheduled',
        completed_at TEXT
      );
      CREATE INDEX IF NOT EXISTS idx_local_study_sessions_profile_date
        ON local_study_sessions (profile_id, scheduled_for);

      -- Guest-mode / offline mirror of mastery_scores. Written first by the diagnostic
      -- assessment (features/onboarding/diagnostic_assessment_screen.dart) and read by the study
      -- planner instead of the "every topic starts at zero" default it used before that screen
      -- existed (docs/CONTINUATION.md).
      CREATE TABLE IF NOT EXISTS local_mastery_scores (
        profile_id TEXT NOT NULL,
        topic_id TEXT NOT NULL,
        subject_id TEXT NOT NULL,
        mastery_estimate REAL NOT NULL DEFAULT 0,
        attempts_count INTEGER NOT NULL DEFAULT 0,
        last_attempt_at TEXT,
        PRIMARY KEY (profile_id, topic_id)
      );
    ''');
  }

  // ---------------------------------------------------------------------------------------
  // Outbox
  // ---------------------------------------------------------------------------------------

  /// Inserts an outbox entry if (and only if) one with this idempotency key doesn't already
  /// exist. Returns true if this call actually inserted a new row (first time seeing this key)
  /// and false if a row with this key already existed (a retry) — callers MUST check this before
  /// applying any further side effect (like crediting XP), or the outbox row becomes decorative
  /// instead of the idempotency guard section 13 requires.
  bool enqueueOutboxEntry({
    required String idempotencyKey,
    required String kind,
    required String payloadJson,
  }) {
    _db.execute(
      'INSERT OR IGNORE INTO outbox_entries (id, kind, payload_json, created_at) VALUES (?, ?, ?, ?)',
      [idempotencyKey, kind, payloadJson, DateTime.now().toIso8601String()],
    );
    return _db.updatedRows > 0;
  }

  List<Map<String, Object?>> unsyncedOutboxEntries() {
    final result = _db.select(
      'SELECT * FROM outbox_entries WHERE synced = 0 ORDER BY created_at ASC',
    );
    return result.map((row) => row).toList();
  }

  void markOutboxEntrySynced(String id) {
    _db.execute('UPDATE outbox_entries SET synced = 1 WHERE id = ?', [id]);
  }

  // ---------------------------------------------------------------------------------------
  // Learner state (XP / streak local cache — see GamificationRepository)
  // ---------------------------------------------------------------------------------------

  Map<String, Object?>? learnerState(String profileId) {
    final result = _db.select(
      'SELECT * FROM local_learner_state WHERE profile_id = ?',
      [profileId],
    );
    return result.isEmpty ? null : result.first;
  }

  void upsertLearnerState({
    required String profileId,
    required int totalXp,
    required int currentStreakDays,
    required int longestStreakDays,
    required String? lastActiveLocalDate,
    required int freezeTokens,
  }) {
    _db.execute(
      '''
      INSERT INTO local_learner_state
        (profile_id, total_xp, current_streak_days, longest_streak_days, last_active_local_date, freeze_tokens)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(profile_id) DO UPDATE SET
        total_xp = excluded.total_xp,
        current_streak_days = excluded.current_streak_days,
        longest_streak_days = excluded.longest_streak_days,
        last_active_local_date = excluded.last_active_local_date,
        freeze_tokens = excluded.freeze_tokens
      ''',
      [
        profileId,
        totalXp,
        currentStreakDays,
        longestStreakDays,
        lastActiveLocalDate,
        freezeTokens,
      ],
    );
  }

  // ---------------------------------------------------------------------------------------
  // Study planner (guest/offline mirror of study_plans + study_sessions)
  // ---------------------------------------------------------------------------------------

  /// Replaces every non-completed session for [profileId] with a freshly generated plan.
  /// Completed sessions are kept (they're history, not a live schedule) so regenerating a plan
  /// never erases what a learner has actually already done.
  void replaceStudySessions(
    String profileId,
    List<Map<String, Object?>> sessions,
  ) {
    _db.execute(
      "DELETE FROM local_study_sessions WHERE profile_id = ? AND status != 'completed'",
      [profileId],
    );
    for (final s in sessions) {
      _db.execute(
        '''
        INSERT INTO local_study_sessions
          (id, profile_id, subject_id, topic_id, topic_title, scheduled_for, duration_minutes, session_kind, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'scheduled')
        ''',
        [
          s['id'],
          profileId,
          s['subject_id'],
          s['topic_id'],
          s['topic_title'],
          s['scheduled_for'],
          s['duration_minutes'],
          s['session_kind'],
        ],
      );
    }
  }

  List<Map<String, Object?>> upcomingStudySessions(
    String profileId, {
    required String fromDateIso,
  }) {
    final result = _db.select(
      "SELECT * FROM local_study_sessions WHERE profile_id = ? AND scheduled_for >= ? "
      "AND status != 'completed' ORDER BY scheduled_for ASC",
      [profileId, fromDateIso],
    );
    return result.toList();
  }

  bool hasAnyStudySessions(String profileId) {
    final result = _db.select(
      'SELECT 1 FROM local_study_sessions WHERE profile_id = ? LIMIT 1',
      [profileId],
    );
    return result.isNotEmpty;
  }

  void updateStudySessionStatus(
    String sessionId,
    String status, {
    String? completedAtIso,
  }) {
    _db.execute(
      'UPDATE local_study_sessions SET status = ?, completed_at = ? WHERE id = ?',
      [status, completedAtIso, sessionId],
    );
  }

  // ---------------------------------------------------------------------------------------
  // Mastery (guest/offline mirror of mastery_scores)
  // ---------------------------------------------------------------------------------------

  Map<String, Object?>? masteryScore(String profileId, String topicId) {
    final result = _db.select(
      'SELECT * FROM local_mastery_scores WHERE profile_id = ? AND topic_id = ?',
      [profileId, topicId],
    );
    return result.isEmpty ? null : result.first;
  }

  void upsertMasteryScore({
    required String profileId,
    required String topicId,
    required String subjectId,
    required double masteryEstimate,
    required int attemptsCount,
  }) {
    _db.execute(
      '''
      INSERT INTO local_mastery_scores
        (profile_id, topic_id, subject_id, mastery_estimate, attempts_count, last_attempt_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(profile_id, topic_id) DO UPDATE SET
        mastery_estimate = excluded.mastery_estimate,
        attempts_count = excluded.attempts_count,
        last_attempt_at = excluded.last_attempt_at
      ''',
      [
        profileId,
        topicId,
        subjectId,
        masteryEstimate,
        attemptsCount,
        DateTime.now().toIso8601String(),
      ],
    );
  }

  void close() => _db.dispose();
}
