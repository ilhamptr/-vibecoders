-- Migration: Add deleted_at for soft delete on area table
-- Non-destructive: additive change only
-- Note: farmer_id already exists (from 20260918155540), so we only add deleted_at

ALTER TABLE public.area 
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_area_deleted_at ON public.area(deleted_at);
CREATE INDEX IF NOT EXISTS idx_area_farmer_id ON public.area(farmer_id);
