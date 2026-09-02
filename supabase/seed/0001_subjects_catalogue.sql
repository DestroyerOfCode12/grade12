-- MatricQuest SA — subject catalogue seed
-- Source: DBE FET CAPS subject list
--   https://www.education.gov.za/Curriculum/CurriculumAssessmentPolicyStatements(CAPS)/CAPSFET.aspx
-- Retrieved: 2026-09-02
-- Status: source_recorded — subject NAMES were read directly from the DBE page above on the date
-- shown. This seed does NOT assert CAPS topic content, weightings, or examination rules; those
-- remain 'unverified' per subject/topic until a curriculum reviewer signs off (see review_tasks).
--
-- South African Sign Language Home Language is included per the 2014 DBE SASL CAPS gazette but is
-- marked 'pending_manual_review' because this seed did not directly retrieve that gazette document —
-- a reviewer must confirm the exact document reference before this subject can leave draft status.

insert into subjects (code, name, category, level, content_status, verification_status, sort_order) values
  -- Languages — Home Language
  ('afrikaans_hl', 'Afrikaans', 'Languages', 'home_language', 'draft', 'source_recorded', 100),
  ('english_hl', 'English', 'Languages', 'home_language', 'draft', 'source_recorded', 101),
  ('isindebele_hl', 'IsiNdebele', 'Languages', 'home_language', 'draft', 'source_recorded', 102),
  ('isixhosa_hl', 'IsiXhosa', 'Languages', 'home_language', 'draft', 'source_recorded', 103),
  ('isizulu_hl', 'IsiZulu', 'Languages', 'home_language', 'draft', 'source_recorded', 104),
  ('sepedi_hl', 'Sepedi', 'Languages', 'home_language', 'draft', 'source_recorded', 105),
  ('sesotho_hl', 'Sesotho', 'Languages', 'home_language', 'draft', 'source_recorded', 106),
  ('setswana_hl', 'Setswana', 'Languages', 'home_language', 'draft', 'source_recorded', 107),
  ('siswati_hl', 'Siswati', 'Languages', 'home_language', 'draft', 'source_recorded', 108),
  ('tshivenda_hl', 'Tshivenda', 'Languages', 'home_language', 'draft', 'source_recorded', 109),
  ('xitsonga_hl', 'Xitsonga', 'Languages', 'home_language', 'draft', 'source_recorded', 110),
  ('sasl_hl', 'South African Sign Language', 'Languages', 'home_language', 'draft', 'pending_manual_review', 111),

  -- Languages — First Additional Language
  ('afrikaans_fal', 'Afrikaans', 'Languages', 'first_additional', 'draft', 'source_recorded', 200),
  ('english_fal', 'English', 'Languages', 'first_additional', 'draft', 'source_recorded', 201),
  ('isindebele_fal', 'IsiNdebele', 'Languages', 'first_additional', 'draft', 'source_recorded', 202),
  ('isixhosa_fal', 'IsiXhosa', 'Languages', 'first_additional', 'draft', 'source_recorded', 203),
  ('isizulu_fal', 'IsiZulu', 'Languages', 'first_additional', 'draft', 'source_recorded', 204),
  ('sepedi_fal', 'Sepedi', 'Languages', 'first_additional', 'draft', 'source_recorded', 205),
  ('sesotho_fal', 'Sesotho', 'Languages', 'first_additional', 'draft', 'source_recorded', 206),
  ('setswana_fal', 'Setswana', 'Languages', 'first_additional', 'draft', 'source_recorded', 207),
  ('siswati_fal', 'Siswati', 'Languages', 'first_additional', 'draft', 'source_recorded', 208),
  ('tshivenda_fal', 'Tshivenda', 'Languages', 'first_additional', 'draft', 'source_recorded', 209),
  ('xitsonga_fal', 'Xitsonga', 'Languages', 'first_additional', 'draft', 'source_recorded', 210),

  -- Languages — Second Additional Language
  ('afrikaans_sal', 'Afrikaans', 'Languages', 'second_additional', 'draft', 'source_recorded', 300),
  ('english_sal', 'English', 'Languages', 'second_additional', 'draft', 'source_recorded', 301),
  ('french_sal', 'French', 'Languages', 'second_additional', 'draft', 'source_recorded', 302),
  ('mandarin_sal', 'Mandarin', 'Languages', 'second_additional', 'draft', 'source_recorded', 303),
  ('isindebele_sal', 'IsiNdebele', 'Languages', 'second_additional', 'draft', 'source_recorded', 304),
  ('isixhosa_sal', 'IsiXhosa', 'Languages', 'second_additional', 'draft', 'source_recorded', 305),
  ('isizulu_sal', 'IsiZulu', 'Languages', 'second_additional', 'draft', 'source_recorded', 306),
  ('sepedi_sal', 'Sepedi', 'Languages', 'second_additional', 'draft', 'source_recorded', 307),
  ('sesotho_sal', 'Sesotho', 'Languages', 'second_additional', 'draft', 'source_recorded', 308),
  ('setswana_sal', 'Setswana', 'Languages', 'second_additional', 'draft', 'source_recorded', 309),
  ('siswati_sal', 'Siswati', 'Languages', 'second_additional', 'draft', 'source_recorded', 310),
  ('tshivenda_sal', 'Tshivenda', 'Languages', 'second_additional', 'draft', 'source_recorded', 311),
  ('xitsonga_sal', 'Xitsonga', 'Languages', 'second_additional', 'draft', 'source_recorded', 312),

  -- Mathematics and Sciences
  ('mathematics', 'Mathematics', 'Mathematics and Sciences', 'core', 'draft', 'source_recorded', 400),
  ('mathematical_literacy', 'Mathematical Literacy', 'Mathematics and Sciences', 'core', 'draft', 'source_recorded', 401),
  ('technical_mathematics', 'Technical Mathematics', 'Mathematics and Sciences', 'core', 'draft', 'source_recorded', 402),
  ('physical_sciences', 'Physical Sciences', 'Mathematics and Sciences', 'core', 'draft', 'source_recorded', 403),
  ('life_sciences', 'Life Sciences', 'Mathematics and Sciences', 'core', 'draft', 'source_recorded', 404),
  ('technical_sciences', 'Technical Sciences', 'Mathematics and Sciences', 'core', 'draft', 'source_recorded', 405),
  ('information_technology', 'Information Technology', 'Mathematics and Sciences', 'core', 'draft', 'source_recorded', 406),
  ('computer_applications_technology', 'Computer Applications Technology', 'Mathematics and Sciences', 'core', 'draft', 'source_recorded', 407),

  -- Commerce and Business
  ('accounting', 'Accounting', 'Commerce and Business', 'core', 'draft', 'source_recorded', 500),
  ('business_studies', 'Business Studies', 'Commerce and Business', 'core', 'draft', 'source_recorded', 501),
  ('economics', 'Economics', 'Commerce and Business', 'core', 'draft', 'source_recorded', 502),

  -- Humanities
  ('geography', 'Geography', 'Humanities', 'core', 'draft', 'source_recorded', 600),
  ('life_orientation', 'Life Orientation', 'Humanities', 'core', 'draft', 'source_recorded', 601),
  ('religion_studies', 'Religion Studies', 'Humanities', 'core', 'draft', 'source_recorded', 602),

  -- Technology and Engineering
  ('civil_technology', 'Civil Technology', 'Technology and Engineering', 'core', 'draft', 'source_recorded', 700),
  ('electrical_technology', 'Electrical Technology', 'Technology and Engineering', 'core', 'draft', 'source_recorded', 701),
  ('mechanical_technology', 'Mechanical Technology', 'Technology and Engineering', 'core', 'draft', 'source_recorded', 702),
  ('engineering_graphics_and_design', 'Engineering Graphics and Design', 'Technology and Engineering', 'core', 'draft', 'source_recorded', 703),
  ('technical_civil_technology', 'Technical: Civil Technology', 'Technology and Engineering', 'core', 'draft', 'source_recorded', 704),
  ('technical_electrical_technology', 'Technical: Electrical Technology', 'Technology and Engineering', 'core', 'draft', 'source_recorded', 705),
  ('technical_mechanical_technology', 'Technical: Mechanical Technology', 'Technology and Engineering', 'core', 'draft', 'source_recorded', 706),

  -- Agriculture
  ('agricultural_science', 'Agricultural Science', 'Agriculture', 'core', 'draft', 'source_recorded', 800),
  ('agricultural_management_practices', 'Agricultural Management Practices', 'Agriculture', 'core', 'draft', 'source_recorded', 801),
  ('agricultural_technology', 'Agricultural Technology', 'Agriculture', 'core', 'draft', 'source_recorded', 802),

  -- Arts and Performance
  ('visual_arts', 'Visual Arts', 'Arts and Performance', 'core', 'draft', 'source_recorded', 900),
  ('dramatic_arts', 'Dramatic Arts', 'Arts and Performance', 'core', 'draft', 'source_recorded', 901),
  ('music', 'Music', 'Arts and Performance', 'core', 'draft', 'source_recorded', 902),
  ('dance_studies', 'Dance Studies', 'Arts and Performance', 'core', 'draft', 'source_recorded', 903),
  ('design_studies', 'Design Studies', 'Arts and Performance', 'core', 'draft', 'source_recorded', 904),

  -- Hospitality, Tourism and Consumer Studies
  ('hospitality_studies', 'Hospitality Studies', 'Hospitality, Tourism and Consumer Studies', 'core', 'draft', 'source_recorded', 1000),
  ('tourism', 'Tourism', 'Hospitality, Tourism and Consumer Studies', 'core', 'draft', 'source_recorded', 1001),
  ('consumer_studies', 'Consumer Studies', 'Hospitality, Tourism and Consumer Studies', 'core', 'draft', 'source_recorded', 1002),

  -- Maritime and Specialised
  ('marine_sciences', 'Marine Sciences', 'Maritime and Specialised', 'core', 'draft', 'source_recorded', 1100),
  ('maritime_economics', 'Maritime Economics', 'Maritime and Specialised', 'core', 'draft', 'source_recorded', 1101),
  ('nautical_science', 'Nautical Science', 'Maritime and Specialised', 'core', 'draft', 'source_recorded', 1102),
  ('equine_studies', 'Equine Studies', 'Maritime and Specialised', 'core', 'draft', 'source_recorded', 1103),
  ('sport_and_exercise_science', 'Sport and Exercise Science', 'Maritime and Specialised', 'core', 'draft', 'source_recorded', 1104)
on conflict (code) do nothing;

-- Record the catalogue-level source citation once, against every subject inserted above.
insert into source_references (entity_type, entity_id, source_title, source_url, retrieved_at, copyright_status, verification_status)
select 'subject', id,
       'DBE: Curriculum Assessment Policy Statements (CAPS) — FET Phase subject list',
       'https://www.education.gov.za/Curriculum/CurriculumAssessmentPolicyStatements(CAPS)/CAPSFET.aspx',
       timestamptz '2026-09-02 00:00:00+02',
       'public_domain_government_document',
       'source_recorded'
from subjects
on conflict do nothing;

-- Every imported subject starts a review task so a human confirms level/category placement,
-- amendments, and (for SASL) the underlying gazette reference before publishing.
insert into review_tasks (entity_type, entity_id, reason, priority)
select 'subject', id, 'imported_catalogue_entry_needs_curriculum_confirmation', 4
from subjects
on conflict do nothing;
