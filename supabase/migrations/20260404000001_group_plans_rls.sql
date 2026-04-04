-- RLS policies for group_plans, plan_participants, plan_votes

ALTER TABLE public.group_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_votes ENABLE ROW LEVEL SECURITY;

-- group_plans: participants can read, creator can manage
CREATE POLICY "group_plans_select" ON public.group_plans
  FOR SELECT USING (
    auth.uid() = created_by
    OR EXISTS (
      SELECT 1 FROM public.plan_participants pp
      WHERE pp.plan_id = id AND pp.user_id = auth.uid()
    )
  );

CREATE POLICY "group_plans_insert" ON public.group_plans
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "group_plans_update" ON public.group_plans
  FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "group_plans_delete" ON public.group_plans
  FOR DELETE USING (auth.uid() = created_by);

-- plan_participants: members of the plan can see participants; creator or self can insert
CREATE POLICY "plan_participants_select" ON public.plan_participants
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.group_plans gp
      WHERE gp.id = plan_id
        AND (gp.created_by = auth.uid() OR auth.uid() = user_id)
    )
  );

CREATE POLICY "plan_participants_insert" ON public.plan_participants
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.group_plans gp
      WHERE gp.id = plan_id AND gp.created_by = auth.uid()
    )
  );

CREATE POLICY "plan_participants_delete" ON public.plan_participants
  FOR DELETE USING (auth.uid() = user_id);

-- plan_votes: participants can read all votes in their plans; own vote to insert/update
CREATE POLICY "plan_votes_select" ON public.plan_votes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.plan_participants pp
      WHERE pp.plan_id = plan_id AND pp.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.group_plans gp
      WHERE gp.id = plan_id AND gp.created_by = auth.uid()
    )
  );

CREATE POLICY "plan_votes_insert" ON public.plan_votes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "plan_votes_update" ON public.plan_votes
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "plan_votes_delete" ON public.plan_votes
  FOR DELETE USING (auth.uid() = user_id);
