-- PMA Mock Test Drill — Phase 1 schema, RLS, helpers
-- Run in Supabase SQL Editor (free tier). Enable extensions in Dashboard first.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE public.user_role AS ENUM ('admin', 'student', 'guest');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.profile_status AS ENUM ('active', 'disabled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.payment_status AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.attempt_status AS ENUM ('in_progress', 'submitted', 'expired');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.attempt_mode AS ENUM ('practice', 'paper');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- Profiles (1:1 with auth.users)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  full_name text,
  phone text,
  city text,
  display_name text,
  role public.user_role NOT NULL DEFAULT 'student',
  credits integer NOT NULL DEFAULT 0 CHECK (credits >= 0),
  status public.profile_status NOT NULL DEFAULT 'active',
  guest_version integer NOT NULL DEFAULT 0,
  guest_fail_count integer NOT NULL DEFAULT 0,
  guest_locked_until timestamptz,
  is_leaderboard_hidden boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.is_admin(uid uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = uid AND p.role = 'admin'
  );
$$;

REVOKE ALL ON FUNCTION public.is_admin(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin(uuid) TO authenticated, anon;

CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles (role);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles (status);

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Auto-create profile on email signup (students)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone, city, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', ''),
    COALESCE(NEW.raw_user_meta_data ->> 'phone', ''),
    COALESCE(NEW.raw_user_meta_data ->> 'city', ''),
    'student'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ---------------------------------------------------------------------------
-- App settings (single-row JSON document + keyed lookups)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_settings (
  id smallint PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  site_name text NOT NULL DEFAULT 'PMA Mock Test Drill',
  price_per_test_pkr integer NOT NULL DEFAULT 500 CHECK (price_per_test_pkr > 0),
  easypaisa_number text NOT NULL DEFAULT '',
  easypaisa_title text NOT NULL DEFAULT '',
  payment_instructions text NOT NULL DEFAULT '',
  support_whatsapp text NOT NULL DEFAULT '',
  support_email text NOT NULL DEFAULT '',
  admin_notification_email text NOT NULL DEFAULT '',
  announcement_banner text NOT NULL DEFAULT '',
  guest_access_id text NOT NULL DEFAULT '',
  guest_password_hash text NOT NULL DEFAULT '',
  guest_version integer NOT NULL DEFAULT 1,
  max_bookmarks integer NOT NULL DEFAULT 100,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER app_settings_updated_at
  BEFORE UPDATE ON public.app_settings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Public-safe settings (never expose admin email or password hash)
CREATE OR REPLACE VIEW public.app_settings_public
WITH (security_invoker = true)
AS
SELECT
  site_name,
  price_per_test_pkr,
  easypaisa_number,
  easypaisa_title,
  payment_instructions,
  support_whatsapp,
  support_email,
  announcement_banner,
  guest_access_id,
  guest_version,
  max_bookmarks
FROM public.app_settings
WHERE id = 1;

GRANT SELECT ON public.app_settings_public TO anon, authenticated;

-- ---------------------------------------------------------------------------
-- Categories & questions
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  slug text NOT NULL UNIQUE,
  group_name text NOT NULL CHECK (group_name IN ('Verbal', 'Academic')),
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id uuid NOT NULL REFERENCES public.categories (id) ON DELETE RESTRICT,
  question_text text NOT NULL,
  opt_a text NOT NULL,
  opt_b text NOT NULL,
  opt_c text NOT NULL,
  opt_d text NOT NULL,
  correct_option char(1) NOT NULL CHECK (correct_option IN ('A', 'B', 'C', 'D')),
  explanation text NOT NULL DEFAULT '',
  difficulty smallint NOT NULL DEFAULT 2 CHECK (difficulty BETWEEN 1 AND 5),
  is_active boolean NOT NULL DEFAULT true,
  is_sample boolean NOT NULL DEFAULT false,
  report_count integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_questions_category_active ON public.questions (category_id, is_active);
CREATE INDEX IF NOT EXISTS idx_questions_active ON public.questions (is_active) WHERE is_active;

CREATE TRIGGER questions_updated_at
  BEFORE UPDATE ON public.questions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Client-safe projection (no correct_option)
CREATE OR REPLACE VIEW public.questions_public
WITH (security_invoker = true)
AS
SELECT
  q.id,
  q.category_id,
  c.name AS category_name,
  c.group_name,
  q.question_text,
  q.opt_a,
  q.opt_b,
  q.opt_c,
  q.opt_d,
  q.difficulty,
  q.is_sample
FROM public.questions q
JOIN public.categories c ON c.id = q.category_id
WHERE q.is_active = true;

GRANT SELECT ON public.questions_public TO authenticated, anon;

CREATE TABLE IF NOT EXISTS public.question_edits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid NOT NULL REFERENCES public.questions (id) ON DELETE CASCADE,
  field_name text NOT NULL,
  old_value text,
  new_value text,
  edited_by uuid REFERENCES public.profiles (id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_question_edits_question ON public.question_edits (question_id);

CREATE TABLE IF NOT EXISTS public.question_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid NOT NULL REFERENCES public.questions (id) ON DELETE CASCADE,
  attempt_id uuid,
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  reason text NOT NULL,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'resolved')),
  resolved_by uuid REFERENCES public.profiles (id),
  resolved_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_question_reports_status ON public.question_reports (status);

-- ---------------------------------------------------------------------------
-- Mock papers
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.papers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text NOT NULL UNIQUE,
  description text NOT NULL DEFAULT '',
  duration_minutes integer NOT NULL DEFAULT 60 CHECK (duration_minutes > 0),
  question_count integer NOT NULL DEFAULT 60 CHECK (question_count > 0),
  negative_mark numeric(4, 2) NOT NULL DEFAULT 0,
  is_published boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER papers_updated_at
  BEFORE UPDATE ON public.papers
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.paper_questions (
  paper_id uuid NOT NULL REFERENCES public.papers (id) ON DELETE CASCADE,
  question_id uuid NOT NULL REFERENCES public.questions (id) ON DELETE RESTRICT,
  sort_order integer NOT NULL DEFAULT 0,
  PRIMARY KEY (paper_id, question_id)
);

CREATE INDEX IF NOT EXISTS idx_paper_questions_paper ON public.paper_questions (paper_id, sort_order);

-- ---------------------------------------------------------------------------
-- Payments & credits
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  sender_number text NOT NULL,
  transaction_id text NOT NULL UNIQUE,
  amount_pkr integer NOT NULL CHECK (amount_pkr > 0),
  status public.payment_status NOT NULL DEFAULT 'pending',
  reject_reason text,
  screenshot_path text NOT NULL,
  reviewed_by uuid REFERENCES public.profiles (id),
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payments_user ON public.payments (user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON public.payments (status);

CREATE TRIGGER payments_updated_at
  BEFORE UPDATE ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.credit_ledger (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  delta integer NOT NULL,
  balance_after integer NOT NULL CHECK (balance_after >= 0),
  reason text NOT NULL,
  payment_id uuid REFERENCES public.payments (id),
  attempt_id uuid,
  created_by uuid REFERENCES public.profiles (id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_credit_ledger_user ON public.credit_ledger (user_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- Attempts
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  mode public.attempt_mode NOT NULL,
  paper_id uuid REFERENCES public.papers (id),
  category_slug text,
  question_ids uuid[] NOT NULL DEFAULT '{}',
  option_orders jsonb NOT NULL DEFAULT '{}',
  started_at timestamptz NOT NULL DEFAULT now(),
  ends_at timestamptz NOT NULL,
  submitted_at timestamptz,
  status public.attempt_status NOT NULL DEFAULT 'in_progress',
  score numeric(8, 2),
  total numeric(8, 2),
  correct_count integer NOT NULL DEFAULT 0,
  wrong_count integer NOT NULL DEFAULT 0,
  skipped_count integer NOT NULL DEFAULT 0,
  percentage numeric(5, 2),
  time_taken_seconds integer,
  answers_detail jsonb,
  review_expires_at timestamptz,
  test_number integer,
  credit_charged boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_attempts_user ON public.attempts (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_attempts_status ON public.attempts (user_id, status);
CREATE INDEX IF NOT EXISTS idx_attempts_review_expires ON public.attempts (review_expires_at)
  WHERE review_expires_at IS NOT NULL;

CREATE TRIGGER attempts_updated_at
  BEFORE UPDATE ON public.attempts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.attempt_answers (
  attempt_id uuid NOT NULL REFERENCES public.attempts (id) ON DELETE CASCADE,
  question_id uuid NOT NULL REFERENCES public.questions (id) ON DELETE RESTRICT,
  selected_option char(1) CHECK (selected_option IN ('A', 'B', 'C', 'D')),
  marked_for_review boolean NOT NULL DEFAULT false,
  bookmarked boolean NOT NULL DEFAULT false,
  answered_at timestamptz,
  PRIMARY KEY (attempt_id, question_id)
);

CREATE INDEX IF NOT EXISTS idx_attempt_answers_attempt ON public.attempt_answers (attempt_id);

CREATE TABLE IF NOT EXISTS public.attempt_category_scores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  attempt_id uuid NOT NULL REFERENCES public.attempts (id) ON DELETE CASCADE,
  category_id uuid NOT NULL REFERENCES public.categories (id),
  correct integer NOT NULL DEFAULT 0,
  total integer NOT NULL DEFAULT 0,
  UNIQUE (attempt_id, category_id)
);

CREATE INDEX IF NOT EXISTS idx_attempt_category_scores_attempt ON public.attempt_category_scores (attempt_id);

CREATE TABLE IF NOT EXISTS public.bookmarks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  question_id uuid NOT NULL REFERENCES public.questions (id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, question_id)
);

CREATE INDEX IF NOT EXISTS idx_bookmarks_user ON public.bookmarks (user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.guest_attempt_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  attempt_id uuid REFERENCES public.attempts (id) ON DELETE SET NULL,
  summary jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_guest_attempt_log_user ON public.guest_attempt_log (user_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_edits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.papers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.paper_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credit_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attempt_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attempt_category_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guest_attempt_log ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY profiles_select_own ON public.profiles
  FOR SELECT TO authenticated
  USING (id = auth.uid() OR public.is_admin());

CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid() OR public.is_admin())
  WITH CHECK (id = auth.uid() OR public.is_admin());

CREATE POLICY profiles_insert_own ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

-- App settings: admin only on base table (public uses view)
CREATE POLICY app_settings_admin ON public.app_settings
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Categories: read all authenticated/anon
CREATE POLICY categories_read ON public.categories
  FOR SELECT TO authenticated, anon
  USING (true);

CREATE POLICY categories_admin ON public.categories
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Questions: NO direct client SELECT (RPCs in later phases). Admin full access.
CREATE POLICY questions_admin ON public.questions
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Question edits / reports
CREATE POLICY question_edits_admin ON public.question_edits
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY question_reports_insert ON public.question_reports
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY question_reports_select ON public.question_reports
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY question_reports_admin_update ON public.question_reports
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Papers
CREATE POLICY papers_read_published ON public.papers
  FOR SELECT TO authenticated, anon
  USING (is_published = true OR public.is_admin());

CREATE POLICY papers_admin ON public.papers
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY paper_questions_read ON public.paper_questions
  FOR SELECT TO authenticated, anon
  USING (
    EXISTS (
      SELECT 1 FROM public.papers p
      WHERE p.id = paper_id AND (p.is_published = true OR public.is_admin())
    )
  );

CREATE POLICY paper_questions_admin ON public.paper_questions
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Payments
CREATE POLICY payments_own ON public.payments
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY payments_insert_own ON public.payments
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY payments_admin_update ON public.payments
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Credit ledger
CREATE POLICY credit_ledger_own ON public.credit_ledger
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

-- Attempts & answers
CREATE POLICY attempts_own ON public.attempts
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY attempt_answers_own ON public.attempt_answers
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.attempts a
      WHERE a.id = attempt_id AND (a.user_id = auth.uid() OR public.is_admin())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.attempts a
      WHERE a.id = attempt_id AND a.user_id = auth.uid()
    )
  );

CREATE POLICY attempt_category_scores_own ON public.attempt_category_scores
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.attempts a
      WHERE a.id = attempt_id AND (a.user_id = auth.uid() OR public.is_admin())
    )
  );

-- Bookmarks
CREATE POLICY bookmarks_own ON public.bookmarks
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Guest attempt log (guest users only see own via profile role check in app; RLS own rows)
CREATE POLICY guest_attempt_log_own ON public.guest_attempt_log
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Storage bucket (run after creating bucket "payment-screenshots" in Dashboard)
-- ---------------------------------------------------------------------------
-- See supabase/migrations/20251015000002_storage_policies.sql

-- ---------------------------------------------------------------------------
-- pg_cron cleanup job (enable pg_cron extension in Dashboard → Database → Extensions)
-- ---------------------------------------------------------------------------
-- See supabase/migrations/20251015000003_cron_cleanup.sql
