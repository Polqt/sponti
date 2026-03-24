-- Allow users to edit their own check-in note/photo without deleting the row.

CREATE POLICY "Users can update own check-ins"
  ON public.check_ins FOR UPDATE
  USING (auth.uid() = user_id);
