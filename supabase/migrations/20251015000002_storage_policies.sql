-- Create bucket first: Supabase Dashboard → Storage → New bucket
-- Name: payment-screenshots | Private | File size limit 5 MB | MIME: image/jpeg, image/png, image/webp

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'payment-screenshots',
  'payment-screenshots',
  false,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Students upload only into their own folder: {user_id}/...
CREATE POLICY payment_screenshots_insert_own ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'payment-screenshots'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY payment_screenshots_select_own_or_admin ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'payment-screenshots'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR public.is_admin()
    )
  );

CREATE POLICY payment_screenshots_delete_admin ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'payment-screenshots'
    AND public.is_admin()
  );
