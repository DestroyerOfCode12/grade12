-- MatricQuest SA — demo vertical-slice content (Mathematics)
-- IMPORTANT: everything inserted here is is_seed_demo_content = true. It exists ONLY to make the
-- onboarding -> lesson -> quiz -> XP -> past paper -> results journey runnable end to end in local
-- dev / CI. It is intentionally published (content_status) so the demo is visible without running
-- the full admin review workflow, but verification_status stays 'unverified' and the mobile app
-- MUST render a "Demo content — not yet curriculum-verified" badge whenever is_seed_demo_content
-- is true, regardless of content_status. Real content goes through supabase/migrations 0003-0006's
-- draft -> in_review -> approved -> published pipeline and admin dashboard (Phase 3), never this file.

do $$
declare
  v_subject_id uuid;
  v_topic_id uuid;
  v_lesson_id uuid;
  v_quiz_id uuid;
  v_q1 uuid; v_q1a uuid; v_q1b uuid; v_q1c uuid; v_q1d uuid;
  v_q2 uuid;
  v_paper_id uuid;
begin
  select id into v_subject_id from subjects where code = 'mathematics';

  insert into topics (subject_id, title, term, learning_outcomes, sort_order, content_status, verification_status)
  values (v_subject_id, 'Functions and Graphs (demo)', 'term_1',
          array['Interpret and sketch graphs of functions', 'Determine intercepts, turning points and asymptotes'],
          1, 'published', 'unverified')
  returning id into v_topic_id;

  insert into lessons (topic_id, title, language_code, estimated_minutes, content_status, verification_status, is_seed_demo_content)
  values (v_topic_id, 'Understanding Linear Functions (demo)', 'en', 6, 'published', 'unverified', true)
  returning id into v_lesson_id;

  insert into lesson_blocks (lesson_id, block_type, sort_order, body_markdown) values
  (v_lesson_id, 'explanation', 1,
   'A linear function has the form **y = mx + c**. Here *m* is the gradient (how steep the line is) and *c* is the y-intercept (where the line crosses the y-axis).'),
  (v_lesson_id, 'simpler_explanation', 2,
   'Think of it as: start at *c*, then for every step of 1 to the right, go up (or down) by *m*.'),
  (v_lesson_id, 'local_example', 3,
   'A prepaid airtime deal costs R2 to connect plus R0.80 per minute. Total cost after *x* minutes is **y = 0.80x + 2** — a linear function you use every time you check your airtime balance.'),
  (v_lesson_id, 'definition_or_formula', 4,
   '**Gradient formula:** m = (y2 − y1) / (x2 − x1). **Standard form:** y = mx + c.'),
  (v_lesson_id, 'worked_example', 5,
   'Find the equation of the line through (1, 5) and (3, 9).\n\nm = (9 − 5) / (3 − 1) = 2\n\nUsing y = mx + c and (1, 5): 5 = 2(1) + c → c = 3\n\nSo **y = 2x + 3**.'),
  (v_lesson_id, 'common_mistakes', 6,
   'Learners often subtract x and y values in the wrong order when finding the gradient — always keep (y2 − y1) over (x2 − x1) using the *same* two points in the *same* order on top and bottom.'),
  (v_lesson_id, 'citation', 7,
   'Demo lesson only — not yet checked against the official CAPS Mathematics document. See subjects.mathematics review task.');

  insert into flashcards (topic_id, front_markdown, back_markdown, is_seed_demo_content) values
  (v_topic_id, 'What does *m* represent in y = mx + c?', 'The gradient (steepness) of the line.', true),
  (v_topic_id, 'What does *c* represent in y = mx + c?', 'The y-intercept — where the line crosses the y-axis.', true);

  insert into quizzes (topic_id, title, quiz_kind, content_status)
  values (v_topic_id, 'Functions checkpoint (demo)', 'checkpoint', 'published')
  returning id into v_quiz_id;

  insert into questions (topic_id, kind, prompt_markdown, difficulty, marks, content_status, verification_status, is_seed_demo_content)
  values (v_topic_id, 'multiple_choice', 'What is the gradient of the line y = 4x − 7?', 1, 1,
          'published', 'unverified', true)
  returning id into v_q1;

  insert into question_options (question_id, label, body_markdown, is_correct, sort_order) values
  (v_q1, 'A', '4', true, 1) returning id into v_q1a;
  insert into question_options (question_id, label, body_markdown, is_correct, sort_order) values
  (v_q1, 'B', '-7', false, 2) returning id into v_q1b;
  insert into question_options (question_id, label, body_markdown, is_correct, sort_order) values
  (v_q1, 'C', '7', false, 3) returning id into v_q1c;
  insert into question_options (question_id, label, body_markdown, is_correct, sort_order) values
  (v_q1, 'D', '-4', false, 4) returning id into v_q1d;

  insert into question_solutions (question_id, solution_markdown, is_official_memorandum, explanation_markdown)
  values (v_q1, 'A: 4', false, 'In y = mx + c, the coefficient of x is the gradient, so m = 4.');

  insert into questions (topic_id, kind, prompt_markdown, difficulty, marks, content_status, verification_status, is_seed_demo_content)
  values (v_topic_id, 'numeric', 'A line passes through (0, 3) and (2, 11). Calculate the gradient.', 2, 2,
          'published', 'unverified', true)
  returning id into v_q2;

  insert into question_solutions (question_id, solution_markdown, is_official_memorandum, explanation_markdown)
  values (v_q2, '4', false, 'm = (11 − 3) / (2 − 0) = 8 / 2 = 4.');

  insert into quiz_questions (quiz_id, question_id, sort_order) values
  (v_quiz_id, v_q1, 1), (v_quiz_id, v_q2, 2);

  -- One demo past paper record so the Papers Library / offline-download / results flow is testable.
  -- No actual PDF is bundled; paper_assets.storage_path points at a placeholder that the app must
  -- treat as unavailable rather than pretending a real DBE file exists.
  insert into papers (subject_id, exam_year, session, paper_number, language_code, exam_type, title,
                       source_url, content_status, association_confidence)
  values (v_subject_id, 2023, 'may_june', 1, 'en', 'nsc',
          'Mathematics Paper 1 (demo record — no bundled file)',
          'https://www.education.gov.za/Curriculum/NationalSeniorCertificate(NSC)Examinations/NSCPastExaminationpapers.aspx',
          'draft', 'unconfirmed')
  returning id into v_paper_id;

  insert into review_tasks (entity_type, entity_id, reason, priority)
  values ('paper', v_paper_id, 'demo_record_needs_real_file_ingestion', 5);
end $$;
