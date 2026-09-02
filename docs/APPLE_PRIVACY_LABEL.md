# Apple Privacy Nutrition Label — checklist for MatricQuest SA

Fill this in App Store Connect → App Privacy. Re-verify against the live production config before
each submission.

## Data Used to Track You
None. MatricQuest SA does not track users across apps/websites for advertising and does not use
the Advertising Identifier (IDFA).

## Data Linked to Your Identity (account users)
| Category | Types | Purpose |
|---|---|---|
| Contact Info | Email address | App functionality (auth) |
| User Content | Photos/questions submitted to Quest Coach | App functionality (AI tutor) |
| Identifiers | User ID | App functionality |
| Usage Data | Lesson/quiz/paper attempts, XP, product interaction | App functionality, analytics |

## Data Not Linked to Your Identity
| Category | Types | Purpose |
|---|---|---|
| Diagnostics | Crash data, performance data | App functionality (opt-out available) |

## Data Not Collected
Location, contacts, browsing history, financial info, health/fitness, sensitive info (race,
religion, sexual orientation, etc.).

## Guest mode note
When a learner uses Guest Mode, no account-linked data leaves the device except a Quest Coach
message/image if they choose to use that feature (unavoidable — it must reach the AI provider to
produce a response), and opt-out-able diagnostics. State this explicitly in the label's description
field so reviewers understand the guest-mode data-minimisation path.

## Children
Declare the app as directed at a mixed-age audience that includes minors (Grade 12 learners are
typically 17-19, some younger). Apple's privacy label does not have a distinct "for kids" toggle
outside the Kids Category, which this app should NOT be listed under — confirm categorisation
during submission and cross-check against `docs/PRIVACY_POLICY_DRAFT.md` §6.

## Before submitting
- Confirm the production AI provider's stance on "linked to identity" — the Quest Coach message
  content is tied to `profile_id` server-side (`tutor_conversations`), so treat it as linked, not
  anonymous, in the label.
- Confirm whether any analytics/crash SDK is compiled into the release build; update the
  Diagnostics row to match reality, not this template.
