-- Run AFTER migrations. Safe to re-run categories/settings; questions use ON CONFLICT where possible.

INSERT INTO public.app_settings (
  id,
  site_name,
  price_per_test_pkr,
  easypaisa_number,
  easypaisa_title,
  payment_instructions,
  support_whatsapp,
  support_email,
  admin_notification_email,
  announcement_banner,
  guest_access_id,
  guest_password_hash,
  guest_version
) VALUES (
  1,
  'PMA Mock Test Drill',
  500,
  '03350008962',
  '', -- Set Easypaisa account title in Admin → Settings (Phase 3 UI) or UPDATE here
  'Send exactly Rs 500 via Easypaisa to the account shown. Enter your transaction ID and upload a clear screenshot.',
  '03350008962',
  'support@example.com',
  'umerluqman93@gmail.com',
  '',
  'GUEST2026',
  crypt('ChangeMeInAdmin', gen_salt('bf')),
  1
)
ON CONFLICT (id) DO UPDATE SET
  site_name = EXCLUDED.site_name,
  price_per_test_pkr = EXCLUDED.price_per_test_pkr,
  easypaisa_number = EXCLUDED.easypaisa_number,
  support_whatsapp = EXCLUDED.support_whatsapp,
  admin_notification_email = EXCLUDED.admin_notification_email,
  guest_access_id = EXCLUDED.guest_access_id;

INSERT INTO public.categories (name, slug, group_name, sort_order) VALUES
  ('Verbal Intelligence', 'verbal-intelligence', 'Verbal', 1),
  ('English', 'english', 'Verbal', 2),
  ('Mathematics', 'mathematics', 'Academic', 3),
  ('Islamic Studies', 'islamic-studies', 'Academic', 4),
  ('Pakistan Studies', 'pakistan-studies', 'Academic', 5),
  ('General Knowledge', 'general-knowledge', 'Academic', 6),
  ('Current Affairs', 'current-affairs', 'Academic', 7)
ON CONFLICT (slug) DO NOTHING;

-- SAMPLE QUESTIONS — verify content before going live (is_sample = true)
WITH cat AS (SELECT id, slug FROM public.categories)
INSERT INTO public.questions (
  category_id, question_text, opt_a, opt_b, opt_c, opt_d, correct_option, explanation, difficulty, is_sample
)
SELECT c.id, q.question_text, q.opt_a, q.opt_b, q.opt_c, q.opt_d, q.correct_option, q.explanation, q.difficulty, true
FROM (VALUES
  ('verbal-intelligence', 'Which word is most opposite to "Benevolent"?', 'Kind', 'Malevolent', 'Generous', 'Humane', 'B', 'Malevolent means wishing harm; opposite of benevolent.', 2),
  ('verbal-intelligence', 'Book : Read :: Fork : ?', 'Eat', 'Write', 'Cook', 'Cut', 'A', 'You use a fork to eat, as you use a book to read.', 1),
  ('verbal-intelligence', 'Complete: A, C, F, J, ?', 'M', 'N', 'O', 'P', 'C', 'Letter gaps increase: +2,+3,+4,+5 → O.', 3),
  ('verbal-intelligence', 'If CLOUD is coded as DMPVE, how is RAIN coded?', 'SBJO', 'QZHM', 'SBKO', 'TCKP', 'A', 'Each letter +1 (sample pattern).', 3),
  ('english', 'Choose the correct sentence:', 'He don''t like tea.', 'He doesn''t likes tea.', 'He doesn''t like tea.', 'He not like tea.', 'C', 'Third person singular present: doesn''t + base verb.', 1),
  ('english', 'Synonym of "Abundant":', 'Scarce', 'Plentiful', 'Tiny', 'Weak', 'B', 'Abundant means existing in large quantities.', 1),
  ('english', 'Antonym of "Transparent":', 'Clear', 'Opaque', 'Visible', 'Open', 'B', 'Opaque means not allowing light through.', 2),
  ('english', 'Fill in: She has been working here ___ 2020.', 'for', 'since', 'from', 'by', 'B', 'Use "since" with a point in time.', 2),
  ('mathematics', 'What is 15% of 240?', '30', '36', '40', '24', 'B', '0.15 × 240 = 36.', 1),
  ('mathematics', 'If x + 5 = 17, then x = ?', '10', '11', '12', '22', 'C', 'x = 17 − 5 = 12.', 1),
  ('mathematics', 'Area of a rectangle 8 cm by 5 cm?', '13 cm²', '26 cm²', '40 cm²', '80 cm²', 'C', 'Area = length × width = 40.', 1),
  ('mathematics', 'Average of 4, 6, and 8?', '5', '6', '7', '8', 'B', '(4+6+8)/3 = 6.', 1),
  ('islamic-studies', 'How many pillars of Islam are there?', '4', '5', '6', '7', 'B', 'Shahada, Salah, Zakat, Sawm, Hajj.', 1),
  ('islamic-studies', 'First revelation was in the cave of?', 'Hira', 'Thawr', 'Uhud', 'Badr', 'A', 'Cave Hira near Makkah.', 1),
  ('islamic-studies', 'Holy Quran was revealed over approximately how many years?', '10', '23', '40', '50', 'B', 'Commonly taught as about 23 years.', 2),
  ('islamic-studies', 'Zakat is obligatory on wealth held for one ___ year.', 'Lunar', 'Solar', 'Calendar', 'Financial', 'A', 'Haul is based on the lunar year.', 2),
  ('islamic-studies', 'Battle of Badr took place in which Hijri year?', '1 AH', '2 AH', '3 AH', '5 AH', 'B', 'Battle of Badr: 2 AH (sample fact—verify).', 3),

  ('pakistan-studies', 'Pakistan Resolution was passed in:', '1940', '1947', '1930', '1949', 'A', 'Lahore Resolution, 23 March 1940.', 1),
  ('pakistan-studies', 'First Governor-General of Pakistan was:', 'Liaquat Ali Khan', 'Muhammad Ali Jinnah', 'Iskander Mirza', 'Ayub Khan', 'B', 'Quaid-e-Azam served as Governor-General.', 1),
  ('pakistan-studies', 'Capital of Pakistan is:', 'Karachi', 'Lahore', 'Islamabad', 'Rawalpindi', 'C', 'Islamabad since 1960s.', 1),
  ('pakistan-studies', 'Indus River enters Pakistan from:', 'China', 'Afghanistan', 'India', 'Nepal', 'C', 'Enters from Ladakh/India region.', 2),
  ('pakistan-studies', 'Objectives Resolution was adopted in:', '1947', '1949', '1956', '1973', 'B', 'March 1949 (sample—verify).', 3),

  ('general-knowledge', 'Largest planet in our solar system?', 'Earth', 'Saturn', 'Jupiter', 'Mars', 'C', 'Jupiter is the largest.', 1),
  ('general-knowledge', 'Human body''s largest organ?', 'Heart', 'Liver', 'Skin', 'Brain', 'C', 'Skin by surface area.', 1),
  ('general-knowledge', 'UN headquarters city?', 'Geneva', 'New York', 'Paris', 'Vienna', 'B', 'New York City.', 1),
  ('general-knowledge', 'Currency of Japan?', 'Yuan', 'Won', 'Yen', 'Ringgit', 'C', 'Japanese Yen.', 1),
  ('general-knowledge', 'Which gas do plants absorb for photosynthesis?', 'Oxygen', 'Nitrogen', 'Carbon dioxide', 'Hydrogen', 'C', 'CO₂ is used in photosynthesis.', 1),

  ('current-affairs', 'Sample: IMF stands for?', 'International Money Fund', 'International Monetary Fund', 'Indian Monetary Forum', 'None', 'B', 'Replace with up-to-date MCQs before launch.', 1),
  ('current-affairs', 'Sample: WHO headquarters is in?', 'Paris', 'Geneva', 'Rome', 'Berlin', 'B', 'World Health Organization, Geneva.', 1),
  ('current-affairs', 'Sample: OIC mainly groups countries of which faith background?', 'Buddhist', 'Christian', 'Muslim', 'Hindu', 'C', 'Organization of Islamic Cooperation.', 1)
) AS q(slug, question_text, opt_a, opt_b, opt_c, opt_d, correct_option, explanation, difficulty)
JOIN cat c ON c.slug = q.slug
WHERE NOT EXISTS (
  SELECT 1 FROM public.questions existing
  WHERE existing.question_text = q.question_text
);

INSERT INTO public.papers (title, slug, description, duration_minutes, question_count, negative_mark, is_published, sort_order)
VALUES
  (
    'PMA Mock Test 1 (Sample)',
    'pma-mock-test-1',
    'Sample paper — 15 MCQs for engine testing. Expand to 60 before production.',
    15,
    15,
    0,
    true,
    1
  ),
  (
    'PMA Mock Test 2 (Sample)',
    'pma-mock-test-2',
    'Sample paper — 15 MCQs for engine testing. Expand to 60 before production.',
    15,
    15,
    0,
    true,
    2
  )
ON CONFLICT (slug) DO NOTHING;

-- Attach first 15 and next 15 active questions to papers (by created order)
INSERT INTO public.paper_questions (paper_id, question_id, sort_order)
SELECT p.id, q.id, q.rn
FROM public.papers p
JOIN LATERAL (
  SELECT id, row_number() OVER (ORDER BY created_at) AS rn
  FROM public.questions
  WHERE is_active = true
) q ON true
WHERE p.slug = 'pma-mock-test-1' AND q.rn BETWEEN 1 AND 15
ON CONFLICT DO NOTHING;

INSERT INTO public.paper_questions (paper_id, question_id, sort_order)
SELECT p.id, q.id, q.rn - 15
FROM public.papers p
JOIN LATERAL (
  SELECT id, row_number() OVER (ORDER BY created_at) AS rn
  FROM public.questions
  WHERE is_active = true
) q ON true
WHERE p.slug = 'pma-mock-test-2' AND q.rn BETWEEN 16 AND 30
-- Requires at least 30 seeded questions
ON CONFLICT DO NOTHING;
