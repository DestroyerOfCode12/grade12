import 'package:uuid/uuid.dart';

/// Generates and persists idempotency keys for retry-safe writes (attempts, paper attempts,
/// XP grants — section 13). The key is created ONCE when the learner starts the action and must
/// be reused for every retry of that same action, including retries after a sync-queue replay.
///
/// Callers should generate the key up front (e.g. when a quiz attempt starts) and store it
/// alongside the local record, not regenerate it on submit — regenerating on submit would defeat
/// the whole purpose of idempotency.
class IdempotencyKeys {
  IdempotencyKeys._();

  static const _uuid = Uuid();

  static String generate() => _uuid.v4();
}
