-- Only the farmer who owns the investment's land may create or remove
-- reports and visual progress updates for that investment.

CREATE POLICY "report_insert_owner"
  ON public.report
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.investment i
      JOIN public.area a ON a.id = i.land_id
      WHERE i.id = report.investment_id
        AND a.farmer_id = auth.uid()
        AND a.deleted_at IS NULL
    )
  );

CREATE POLICY "report_delete_owner"
  ON public.report
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.investment i
      JOIN public.area a ON a.id = i.land_id
      WHERE i.id = report.investment_id
        AND a.farmer_id = auth.uid()
    )
  );

CREATE POLICY "update_insert_owner"
  ON public.update
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.investment i
      JOIN public.area a ON a.id = i.land_id
      WHERE i.id = update.investment_id
        AND a.farmer_id = auth.uid()
        AND a.deleted_at IS NULL
    )
  );

CREATE POLICY "update_delete_owner"
  ON public.update
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.investment i
      JOIN public.area a ON a.id = i.land_id
      WHERE i.id = update.investment_id
        AND a.farmer_id = auth.uid()
    )
  );

CREATE POLICY "investment_reports_insert_owner"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'investment_reports'
    AND EXISTS (
      SELECT 1
      FROM public.investment i
      JOIN public.area a ON a.id = i.land_id
      WHERE i.id::text = split_part(name, '/', 1)
        AND a.farmer_id = auth.uid()
        AND a.deleted_at IS NULL
    )
  );

CREATE POLICY "investment_reports_select_owner"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'investment_reports'
    AND EXISTS (
      SELECT 1
      FROM public.investment i
      JOIN public.area a ON a.id = i.land_id
      WHERE i.id::text = split_part(name, '/', 1)
        AND a.farmer_id = auth.uid()
    )
  );

CREATE POLICY "investment_reports_delete_owner"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'investment_reports'
    AND EXISTS (
      SELECT 1
      FROM public.investment i
      JOIN public.area a ON a.id = i.land_id
      WHERE i.id::text = split_part(name, '/', 1)
        AND a.farmer_id = auth.uid()
    )
  );

CREATE POLICY "investment_updates_insert_owner"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'investment_updates'
    AND EXISTS (
      SELECT 1
      FROM public.investment i
      JOIN public.area a ON a.id = i.land_id
      WHERE i.id::text = split_part(name, '/', 1)
        AND a.farmer_id = auth.uid()
        AND a.deleted_at IS NULL
    )
  );

CREATE POLICY "investment_updates_select_owner"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'investment_updates'
    AND EXISTS (
      SELECT 1
      FROM public.investment i
      JOIN public.area a ON a.id = i.land_id
      WHERE i.id::text = split_part(name, '/', 1)
        AND a.farmer_id = auth.uid()
    )
  );

CREATE POLICY "investment_updates_delete_owner"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'investment_updates'
    AND EXISTS (
      SELECT 1
      FROM public.investment i
      JOIN public.area a ON a.id = i.land_id
      WHERE i.id::text = split_part(name, '/', 1)
        AND a.farmer_id = auth.uid()
    )
  );
