-- Add multi-photo support to check_ins while preserving legacy photo_url data.

ALTER TABLE public.check_ins
ADD COLUMN IF NOT EXISTS photos JSONB NOT NULL DEFAULT '[]'::jsonb;

UPDATE public.check_ins
SET photos = CASE
  WHEN photo_url IS NOT NULL AND photo_url <> '' THEN jsonb_build_array(photo_url)
  ELSE '[]'::jsonb
END
WHERE photos = '[]'::jsonb;
