# Deployment — MatricQuest SA

## Backend (Supabase)

1. **Migrations**: `supabase db push` applies `supabase/migrations/*.sql` in numeric order against
   the linked project. Migrations are additive/idempotent-guarded (`if not exists`, `do $$ ...
   exception when duplicate_object`) so re-running is safe.
2. **Edge Functions**: `supabase functions deploy quest-coach` (repeat per function as more are
   added). Secrets via `supabase secrets set` — never via a committed file.
3. **Storage buckets**: create a `papers` bucket (private, signed-URL access only) and a
   `lesson-media` bucket before the ingestion pipeline (Phase 3) goes live.
4. **RLS verification**: run `supabase/tests/rls_and_idempotency_test.sql` against a staging
   project before every production migration push — RLS regressions are the highest-severity class
   of bug this app can ship (learner data crossing accounts).

## Mobile app releases

### Android

```bash
cd app
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://<prod-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<prod-anon-key>
```

Signing: create `app/android/key.properties` (gitignored, see `.gitignore`) pointing at your
release keystore, and wire it into `app/android/app/build.gradle` per the standard Flutter
[Android deployment guide](https://docs.flutter.dev/deployment/android) before this produces a
Play-Store-installable bundle — the current `build.gradle` from `flutter create` is debug-signed
only. CI's `android-release-bundle` job builds unsigned; add the keystore as a GitHub Actions
secret and extend that job once signing is configured.

### iOS

No signed IPA can be produced without an active Apple Developer Program membership, a distribution
certificate, and a provisioning profile — none of which exist in this repository by design (see
`docs/ADR.md` §2.8). Once you have those:

1. Open `app/ios/Runner.xcworkspace` in Xcode on a macOS machine.
2. Set your Team under Signing & Capabilities.
3. `flutter build ipa` from the `app/` directory.
4. Upload via Xcode Organizer or `xcrun altool` / Transporter.

CI's `ios-unsigned-archive.yml` only proves the code compiles for iOS — it is not a release
pipeline.

## Rollback

- **Backend**: every publishable content row has a `content_versions` snapshot (0003 migration) —
  roll back a bad publish via the admin dashboard's version history (Phase 3) or, until that UI
  exists, `update <table> set ... from content_versions where ...` restoring the prior snapshot's
  fields, then re-run the RLS test suite.
- **Mobile app**: standard store-side rollback (halt rollout / revert to previous release) since
  content is served from the backend, not baked into the binary — this is the whole point of
  section 2's "curriculum can update without an app release" requirement.

## Environments

Recommend three Supabase projects: `dev` (seeded, unstable), `staging` (mirrors prod schema, used
for RLS/migration verification before every push), `prod`. Never point a debug build at `prod`
using developer credentials — build-time `--dart-define` values should come from CI secrets scoped
per environment, never a developer's local shell history.
