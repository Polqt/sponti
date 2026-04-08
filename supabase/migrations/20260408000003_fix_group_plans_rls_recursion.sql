-- Fix infinite recursion in plan_participants RLS.
--
-- Root cause:
--   group_plans_select  → queries plan_participants (triggers plan_participants_select)
--   plan_participants_select → queries group_plans   (triggers group_plans_select) → loop
--
-- Fix: rewrite plan_participants_select so it never touches group_plans.
--   A user can see a participant row when:
--     a) they ARE that participant (user_id = auth.uid()), OR
--     b) they are another participant in the same plan
--        (checked via a self-join on plan_participants only, no group_plans involved)
--
-- This is equivalent in practice: if you're in the plan you can see everyone in it.

DROP POLICY IF EXISTS "plan_participants_select" ON public.plan_participants;

CREATE POLICY "plan_participants_select" ON public.plan_participants
  FOR SELECT USING (
    -- The current user is this participant row
    auth.uid() = user_id
    OR
    -- The current user is also a participant in the same plan
    EXISTS (
      SELECT 1 FROM public.plan_participants other
      WHERE other.plan_id = plan_participants.plan_id
        AND other.user_id = auth.uid()
    )
  );
