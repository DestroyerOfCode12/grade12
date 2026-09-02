# MatricQuest SA — Privacy Policy (DRAFT)

**This is a draft prepared for legal review. It is not a substitute for advice from a South African
attorney familiar with the Protection of Personal Information Act 4 of 2013 (POPIA), and must not
be published to end users until reviewed and approved.**

Last updated: [date of legal review] · Version: 0.1-draft

## 1. Who we are
MatricQuest SA ("we", "us", "the app") is a study application for South African Grade 12 learners.
[Insert responsible party / operator legal name, registration details, and contact details for the
Information Officer, as POPIA requires.]

## 2. Data we collect

### 2.1 If you use Guest Mode
No account is created. Study progress, XP, and preferences are stored only on your device. Nothing
is sent to our servers except anonymous, aggregated crash/performance diagnostics (opt-out
available in Settings), and — only if you use Quest Coach — the specific question you ask, needed
to generate a response.

### 2.2 If you create an account
- **Account data:** email address (or OAuth identifier), a nickname you choose (never your real
  name unless you choose to use it as your nickname, which we discourage), timezone, and — only if
  you provide it — date of birth, used solely to apply extra protections for minors and never shown
  to other users.
- **Study data:** subjects selected, lessons completed, quiz/paper attempts and scores, mastery
  estimates, study plan, streaks, XP, achievements.
- **Quest Coach data:** messages you send the tutor, and photos of questions you choose to submit.
  These are sent to our AI processing service (see §4) to generate a response and are logged
  against your account for continuity and abuse prevention.
- **Device data:** push notification token (if you enable reminders), coarse device/OS info for
  crash diagnostics.

### 2.3 We do not collect
Government ID numbers, financial/payment details (there is no in-app purchase requiring these),
precise location, contacts, or biometric data. We do not use advertising SDKs and do not build
advertising profiles of children (§6).

## 3. Why we process your data (POPIA lawful-basis summary)
- To provide the core study features you use (contract/consent).
- To personalise your study plan and mastery estimates from your own attempt history (consent).
- To operate Quest Coach's rate limiting and abuse prevention (legitimate interest, proportionate
  to keeping the service usable and its costs sustainable).
- To keep an audit trail of administrator actions on content (legitimate interest — content
  integrity and safety).

## 4. Sharing with third parties
- **Supabase** (database, authentication, file storage) — infrastructure processor, contractually
  bound to protect your data and not use it for their own purposes.
- **AI processing provider** (currently Anthropic) — processes only the specific Quest Coach
  message/image you submit, to generate a response; not used to train the provider's models unless
  their terms are changed and this policy is updated first. [Confirm exact data-retention terms
  with the provider before production launch and reference them here.]
- **Push notification services** (Firebase Cloud Messaging / Apple Push Notification service) —
  delivers reminders you opted into; receives only a device token, not your study content.
- We do **not** sell learner data, and we do not share it for third-party advertising or profiling.

## 5. Your rights under POPIA
You may request: access to the personal information we hold about you, correction of inaccurate
information, and deletion of your account and associated data. Use **Settings → Privacy → Export my
data** or **Delete my account** in the app, or contact [Information Officer contact] directly. We
will act on deletion requests within [X] days, subject to legally required retention (e.g. abuse
investigation records held only as long as necessary).

## 6. Children's data
Many of our users are minors. We minimise what we collect (§2), never display a learner's real name
publicly, disable direct messaging between learners, keep leaderboards opt-in and nickname-only, and
do not run advertising or profiling directed at children. Where a learner indicates they are under
the age our jurisdiction requires parental consent for, [insert your chosen consent mechanism —
e.g. school-mediated consent, parental email confirmation] applies before account creation proceeds.

## 7. Security
See `docs/THREAT_MODEL.md` for the full technical detail. In summary: encryption in transit (TLS)
and at rest, row-level database access control so learners can only ever read their own study data,
and an append-only audit log of administrator actions.

## 8. Retention
Study data is retained while your account is active. On account deletion, personal identifiers are
removed within [X] days; aggregated, de-identified usage statistics may be retained for product
improvement. Guest-mode data never reaches our servers and is deleted when you clear the app or
uninstall it.

## 9. Changes to this policy
We will notify you in-app of material changes before they take effect.

## 10. Contact
[Information Officer name/role, email, physical address, and the Information Regulator's contact
details as required by POPIA.]
