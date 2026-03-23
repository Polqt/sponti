-- Migration: Auto-increment/decrement check_in_count on locations
-- when rows are inserted/deleted in check_ins table.

-- Ensure check_in_count column exists on locations (add if missing)
ALTER TABLE public.locations
  ADD COLUMN IF NOT EXISTS check_in_count INTEGER NOT NULL DEFAULT 0;

-- Back-fill existing counts
UPDATE public.locations l
SET check_in_count = (
  SELECT COUNT(*) FROM public.check_ins c WHERE c.location_id = l.id
);

-- Trigger function
-- SECURITY DEFINER runs as the function owner (postgres/service role),
-- which bypasses RLS so the UPDATE on locations is never blocked.
CREATE OR REPLACE FUNCTION public.update_location_check_in_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.locations
    SET check_in_count = check_in_count + 1
    WHERE id = NEW.location_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.locations
    SET check_in_count = GREATEST(check_in_count - 1, 0)
    WHERE id = OLD.location_id;
  END IF;
  RETURN NULL;
END;
$$;

-- Grant execute so the trigger can fire regardless of caller
GRANT EXECUTE ON FUNCTION public.update_location_check_in_count() TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_location_check_in_count() TO anon;

-- Drop trigger if it already exists (idempotent)
DROP TRIGGER IF EXISTS trg_check_in_count ON public.check_ins;

CREATE TRIGGER trg_check_in_count
AFTER INSERT OR DELETE ON public.check_ins
FOR EACH ROW EXECUTE FUNCTION public.update_location_check_in_count();
