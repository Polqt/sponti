-- Migration: Remove the duplicate trg_check_in_count trigger.
-- on_checkin_change (from 20260308000006_triggers.sql) already handles
-- check_in_count increments/decrements correctly.
-- Having two triggers on the same event was causing double-counting.

DROP TRIGGER IF EXISTS trg_check_in_count ON public.check_ins;
DROP FUNCTION IF EXISTS public.update_location_check_in_count();
