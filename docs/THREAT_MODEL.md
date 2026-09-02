# Threat Model — MatricQuest SA

Scope: mobile app, Supabase backend (Postgres/Auth/Storage/Edge Functions), admin dashboard.
Method: STRIDE-style walk of section 14's required areas. This is a living document — update it
whenever a new data flow or integration is added, and before every production release.

## 1. Authentication & session handling
| Threat | Mitigation |
|---|---|
| Credential stuffing / brute force against Supabase Auth | Supabase Auth's built-in rate limiting + our own login-attempt UI backoff; encourage OAuth (Google/Apple) over passwords where possible; no custom password storage in our tables. |
| Session/token theft from device storage | Supabase session tokens stored via `flutter_secure_storage` (Keychain/Keystore-backed), never in `SharedPreferences`/plain SQLite. |
| Guest-mode data being silently linked to the wrong account on sign-up | Merge flow requires explicit confirmation before local guest progress is attached to a newly created account; never auto-merges by device ID alone. |

## 2. Insecure storage (device & server)
| Threat | Mitigation |
|---|---|
| Local Drift DB readable if device is compromised | SQLCipher-backed encryption for the local database (see CONTINUATION.md for rollout status); no API keys or tokens are ever written to Drift. |
| Downloaded past papers/media tampered with in transit or at rest | `file_checksum` (sha256) recorded per `papers`/`paper_assets` row at ingestion; app verifies checksum after download before marking a download `complete`. |
| Data at rest in Postgres | Supabase-managed encryption at rest; RLS is the primary access boundary, not obscurity. |
| Data in transit | TLS everywhere (Supabase endpoints, Storage signed URLs); no cleartext HTTP fallback. |

## 3. API abuse
| Threat | Mitigation |
|---|---|
| A learner's client forging another learner's `profile_id` in a write | Every RLS policy checks `auth.uid() = profile_id`; the idempotent RPCs (`grant_xp`, `submit_attempt`, `record_daily_activity`) additionally `raise exception` on mismatch inside `SECURITY DEFINER`, so even a bug in a future RLS policy has a second gate. |
| Replayed/duplicated attempt or XP-grant requests (flaky mobile network) | Idempotency keys + unique constraints (`docs/DATA_MODEL.md#idempotency`) make retries no-ops. |
| Scraping the full question bank via the public API | Only `content_status = 'published'` rows are readable at all; pagination + Supabase's connection/row limits; consider a Postgres statement timeout on anon/authenticated roles if scraping is observed. |
| Leaderboard used to enumerate learners | `leaderboard_entries`/`public_leaderboard_profiles` only exposes opted-in, non-private nicknames — never real names, emails, or IDs beyond the profile UUID needed to render the row. |

## 4. Prompt injection (Quest Coach)
| Threat | Mitigation |
|---|---|
| A learner's message tries to make Quest Coach reveal its system prompt or another learner's data | System prompt explicitly instructs the model never to reveal instructions/keys/other users' data; the model is never given any other learner's rows — retrieval is scoped to published curriculum content only, not user data. |
| Content injected via a photographed question tries to redirect the tutor into fabricating an official answer | Grounding is retrieval-only: the model is told to answer only from the `CONTEXT` block sourced from published content, and to say "could not verify" when nothing matches — this is enforced by prompt instructions today, with output-citation checking (does the response's claimed sources exist in `sources[]`) as a Phase 4 hardening item, tracked in CONTINUATION.md. |
| Cost-exhaustion via long/repeated prompts | `tutor_usage_daily` caps requests and estimated cost per learner per day; Edge Function returns 429 once the cap is hit. |

## 5. Malicious files (past-paper ingestion & uploads)
| Threat | Mitigation |
|---|---|
| A malicious PDF uploaded as a "past paper" during admin ingestion | Admin-only upload (staff RLS); MIME-type + magic-byte validation before storage write (Phase 3 ingestion pipeline item); checksum recorded so a later compromise of the stored object is detectable; PDFs served to learners via Supabase Storage, rendered by a PDF viewer library, never executed. |
| A photographed "ask a question" image used as an attack vector against the vision model or storage | Size/type validation client-side before upload; images stored under the learner's own private storage path (RLS-equivalent Storage policy), never made public. |

## 6. Data leakage
| Threat | Mitigation |
|---|---|
| One learner's attempt/mastery data visible to another | RLS on every learner-owned table (section "Learner-owned data" in `0011_row_level_security.sql`). |
| Admin dashboard analytics re-identifying individual learners | Analytics views aggregate; no raw learner-level export without `admin` role, and no analytics event ever includes a learner's real name (profiles rarely have one) or contact details. |
| Third-party AI provider retaining learner questions | Only the learner's message text + retrieved published content is sent — never other learners' data, never admin credentials; document the provider's data-retention terms in `docs/SETUP.md` before enabling in production and disclose in the privacy policy. |

## 7. Administrator-account compromise
| Threat | Mitigation |
|---|---|
| A compromised `admin`/`content_reviewer` account publishing false or harmful content | `content_versions` keeps a full history for rollback; `audit_log` is append-only and records every publish/role-change; content still needs `content_status = 'published'` to reach learners, so a compromised reviewer-only account cannot publish without `admin`/`super_admin` (role boundaries enforced in RLS, not just UI). |
| Privilege escalation via a bug in role assignment | `trg_prevent_role_self_escalation` (0013) blocks any `role` change on `profiles` unless the caller already has staff privileges; the admin dashboard changes roles only via `admin_set_user_role()`, which writes to `audit_log` in the same transaction. |

## 8. Outstanding items (tracked in CONTINUATION.md, not yet implemented)
- Output-citation verification on Quest Coach responses (cross-check cited entity IDs actually
  exist and are published before returning them to the client).
- SQLCipher rollout for the local Drift database.
- Automated dependency/CVE scanning in CI (`flutter pub outdated` / `osv-scanner` step).
