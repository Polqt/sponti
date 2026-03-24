-- Ensure the remote storage bucket and policies exist for review/check-in photo uploads.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'location-photos',
  'location-photos',
  true,
  5242880,
  ARRAY['image/png', 'image/jpeg', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Location photos are viewable by everyone'
  ) THEN
    CREATE POLICY "Location photos are viewable by everyone"
      ON storage.objects FOR SELECT
      USING (bucket_id = 'location-photos');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Authenticated users can upload location photos'
  ) THEN
    CREATE POLICY "Authenticated users can upload location photos"
      ON storage.objects FOR INSERT
      TO authenticated
      WITH CHECK (bucket_id = 'location-photos');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Users can update own location photos'
  ) THEN
    CREATE POLICY "Users can update own location photos"
      ON storage.objects FOR UPDATE
      TO authenticated
      USING (bucket_id = 'location-photos' AND owner = auth.uid())
      WITH CHECK (bucket_id = 'location-photos' AND owner = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Users can delete own location photos'
  ) THEN
    CREATE POLICY "Users can delete own location photos"
      ON storage.objects FOR DELETE
      TO authenticated
      USING (bucket_id = 'location-photos' AND owner = auth.uid());
  END IF;
END $$;
