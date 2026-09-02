# Google Play Data Safety — checklist for MatricQuest SA

Fill this in the Play Console "App content → Data safety" form. Values below reflect the schema in
`supabase/migrations/` and should be re-verified against the actual production configuration before
each submission — this file is guidance, not a substitute for checking the live console form.

## Data collected and shared

| Data type | Collected? | Shared with 3rd party? | Purpose | Optional? |
|---|---|---|---|---|
| Email address | Yes (account users only) | No | Account creation/auth | Yes — guest mode avoids this |
| Name (nickname) | Yes | Only opted-in leaderboard rows, nickname only | App functionality, social features | Yes (leaderboard opt-in) |
| User IDs | Yes | No | Account management | No, if you have an account |
| Photos (Quest Coach question images) | Yes, only if submitted | Yes — sent to AI processing provider to generate a response | App functionality (AI tutor) | Yes |
| App activity (lesson/quiz/paper attempts, XP) | Yes | No | App functionality, personalisation | No, if you have an account; guest mode keeps this on-device only |
| App info and performance (crash logs) | Yes | Possibly, via crash-reporting SDK if enabled | Analytics | Yes (opt-out in Settings) |
| Device or other IDs | Yes (push token only, if reminders enabled) | Shared with FCM/APNs to deliver notifications | App functionality | Yes |

## Data NOT collected
Financial info, precise location, contacts, SMS/call logs, health/fitness data, government ID
numbers. No advertising identifiers are collected and no advertising SDK is integrated.

## Security practices to declare
- Data is encrypted in transit (TLS).
- Users can request data deletion (in-app account deletion flow + Privacy Policy contact).
- Independent security review: [attach summary of `docs/THREAT_MODEL.md` and any external
  pentest once performed].

## Data safety statements requiring specific confirmation before submission
- Confirm final production AI provider's data-retention/training-use terms (§4 of
  `docs/PRIVACY_POLICY_DRAFT.md`) before answering "is data used to improve the app/AI".
- Confirm whether a crash-reporting SDK (e.g. Firebase Crashlytics) is enabled in the shipped build;
  toggle the "Crash logs" / "Diagnostics" rows accordingly.
- Re-confirm child-directed status: this app is *not* primarily directed at children under 13 in
  the Play Console sense (it targets Grade 12 learners, typically 17-19), but does serve minors —
  answer the "Families" section questions accordingly, and keep ads/analytics settings consistent
  with §6 of the Privacy Policy (no ad profiling of children).
