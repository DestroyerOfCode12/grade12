import 'package:flutter_test/flutter_test.dart';
import 'package:matricquest_admin/domain/services/content_lifecycle.dart';

void main() {
  group('ContentLifecycle transitions', () {
    test('draft can move to in_review or archived, nothing else', () {
      final allowed = ContentLifecycle.allowedNextStates(ContentStatus.draft);
      expect(
        allowed,
        containsAll([ContentStatus.inReview, ContentStatus.archived]),
      );
      expect(allowed, isNot(contains(ContentStatus.published)));
    });

    test('draft cannot jump straight to published (review-before-publish is enforced)', () {
      expect(
        ContentLifecycle.canTransition(
          ContentStatus.draft,
          ContentStatus.published,
        ),
        isFalse,
      );
    });

    test('published is only reachable from approved', () {
      expect(
        ContentLifecycle.canTransition(
          ContentStatus.approved,
          ContentStatus.published,
        ),
        isTrue,
      );
      expect(
        ContentLifecycle.canTransition(
          ContentStatus.draft,
          ContentStatus.published,
        ),
        isFalse,
      );
      expect(
        ContentLifecycle.canTransition(
          ContentStatus.inReview,
          ContentStatus.published,
        ),
        isFalse,
      );
      expect(
        ContentLifecycle.canTransition(
          ContentStatus.rejected,
          ContentStatus.published,
        ),
        isFalse,
      );
    });

    test('every state has at least one legal exit (nothing is a dead end)', () {
      for (final status in ContentStatus.values) {
        expect(
          ContentLifecycle.allowedNextStates(status),
          isNotEmpty,
          reason: '$status has no exit',
        );
      }
    });

    test('archived content can be revived back to draft', () {
      expect(
        ContentLifecycle.canTransition(
          ContentStatus.archived,
          ContentStatus.draft,
        ),
        isTrue,
      );
    });
  });

  group('ContentLifecycle.canPublish', () {
    test('seed/demo content can never be published, regardless of verification status', () {
      final result = ContentLifecycle.canPublish(
        isSeedDemoContent: true,
        verificationStatus: 'verified',
      );
      expect(result, isFalse);
    });

    test('unverified non-demo content cannot be published', () {
      final result = ContentLifecycle.canPublish(
        isSeedDemoContent: false,
        verificationStatus: 'unverified',
      );
      expect(result, isFalse);
    });

    test('verified non-demo content can be published', () {
      final result = ContentLifecycle.canPublish(
        isSeedDemoContent: false,
        verificationStatus: 'verified',
      );
      expect(result, isTrue);
    });

    test('source_recorded non-demo content can be published', () {
      final result = ContentLifecycle.canPublish(
        isSeedDemoContent: false,
        verificationStatus: 'source_recorded',
      );
      expect(result, isTrue);
    });

    test('disputed content cannot be published', () {
      final result = ContentLifecycle.canPublish(
        isSeedDemoContent: false,
        verificationStatus: 'disputed',
      );
      expect(result, isFalse);
    });
  });

  group('contentStatus <-> db string round-trip', () {
    test('every enum value round-trips through the db string conversion', () {
      for (final status in ContentStatus.values) {
        final dbValue = contentStatusToDb(status);
        expect(contentStatusFromDb(dbValue), status);
      }
    });
  });
}
