-- Requires pg_cron extension (Supabase free tier: Database → Extensions → pg_cron)

CREATE EXTENSION IF NOT EXISTS pg_cron;

CREATE OR REPLACE FUNCTION public.cleanup_expired_review_details()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  cleared integer;
BEGIN
  UPDATE public.attempts
  SET answers_detail = NULL,
      updated_at = now()
  WHERE review_expires_at IS NOT NULL
    AND review_expires_at < now()
    AND answers_detail IS NOT NULL;

  GET DIAGNOSTICS cleared = ROW_COUNT;
  RETURN cleared;
END;
$$;

REVOKE ALL ON FUNCTION public.cleanup_expired_review_details() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_review_details() TO authenticated;

-- Every 10 minutes
SELECT cron.schedule(
  'cleanup-expired-review-details',
  '*/10 * * * *',
  $$SELECT public.cleanup_expired_review_details();$$
);
