-- Store the exact Supabase Storage object paths alongside the returned URLs.
-- report.file_url remains the document URL; report.file_path is its bucket path.
-- update.image_url remains the image URL array; update.image_path mirrors it
-- positionally with the corresponding bucket paths.

ALTER TABLE public.report
  ADD COLUMN IF NOT EXISTS file_path text;

ALTER TABLE public.update
  ADD COLUMN IF NOT EXISTS image_path text[];

-- Keep the buckets private. APIs return short-lived signed URLs and persist
-- the durable object paths in the columns above.
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('investment_reports', 'investment_reports', false),
  ('investment_updates', 'investment_updates', false)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;
