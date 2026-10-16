-- ============================================================
-- RLS Policies: area, area_images, area_documents
-- Non-destructive: enabling RLS + adding policies only
-- ============================================================
-- 
-- ATURAN BISNIS:
--   • Petani (farmer) bisa CRUD lahan miliknya sendiri
--   • Investor (authenticated user) bisa READ semua lahan aktif (belum di-delete)
--   • Tidak ada yang bisa hard-DELETE (pakai soft delete via deleted_at)
--   • area_images & area_documents ikut akses lahannya
-- ============================================================


-- ─────────────────────────────────────────
-- TABLE: area
-- ─────────────────────────────────────────
ALTER TABLE public.area ENABLE ROW LEVEL SECURITY;

-- Siapapun yang login bisa lihat lahan yang aktif (belum soft-delete)
-- Investor perlu ini untuk browse lahan yang bisa diinvest
CREATE POLICY "area_select_authenticated"
  ON public.area
  FOR SELECT
  TO authenticated
  USING (deleted_at IS NULL);

-- Petani juga bisa lihat lahan miliknya sendiri yang sudah di-delete
-- (untuk keperluan histori)
CREATE POLICY "area_select_own_deleted"
  ON public.area
  FOR SELECT
  TO authenticated
  USING (farmer_id = auth.uid());

-- Hanya bisa insert lahan atas nama diri sendiri
CREATE POLICY "area_insert_own"
  ON public.area
  FOR INSERT
  TO authenticated
  WITH CHECK (farmer_id = auth.uid());

-- Hanya petani pemilik yang bisa update lahannya sendiri (dan belum di-delete)
CREATE POLICY "area_update_own"
  ON public.area
  FOR UPDATE
  TO authenticated
  USING (farmer_id = auth.uid() AND deleted_at IS NULL)
  WITH CHECK (farmer_id = auth.uid());

-- Hard DELETE diblokir semua orang — pakai soft delete (set deleted_at)
-- Tidak ada policy DELETE → otomatis blocked


-- ─────────────────────────────────────────
-- TABLE: area_images
-- ─────────────────────────────────────────
ALTER TABLE public.area_images ENABLE ROW LEVEL SECURITY;

-- Siapapun yang login bisa lihat gambar lahan yang aktif
CREATE POLICY "area_images_select_authenticated"
  ON public.area_images
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.area a
      WHERE a.id = area_images.area_id
        AND a.deleted_at IS NULL
    )
  );

-- Hanya petani pemilik lahan yang bisa tambah/hapus gambar
CREATE POLICY "area_images_insert_own"
  ON public.area_images
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.area a
      WHERE a.id = area_images.area_id
        AND a.farmer_id = auth.uid()
        AND a.deleted_at IS NULL
    )
  );

CREATE POLICY "area_images_delete_own"
  ON public.area_images
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.area a
      WHERE a.id = area_images.area_id
        AND a.farmer_id = auth.uid()
    )
  );


-- ─────────────────────────────────────────
-- TABLE: area_documents
-- ─────────────────────────────────────────
ALTER TABLE public.area_documents ENABLE ROW LEVEL SECURITY;

-- Hanya petani pemilik yang bisa lihat dokumen lahannya (sertifikat tanah = sensitif)
CREATE POLICY "area_documents_select_own"
  ON public.area_documents
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.area a
      WHERE a.id = area_documents.area_id
        AND a.farmer_id = auth.uid()
    )
  );

-- Hanya petani pemilik yang bisa upload dokumen ke lahannya
CREATE POLICY "area_documents_insert_own"
  ON public.area_documents
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.area a
      WHERE a.id = area_documents.area_id
        AND a.farmer_id = auth.uid()
        AND a.deleted_at IS NULL
    )
  );

-- Hanya petani pemilik yang bisa hapus dokumennya
CREATE POLICY "area_documents_delete_own"
  ON public.area_documents
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.area a
      WHERE a.id = area_documents.area_id
        AND a.farmer_id = auth.uid()
    )
  );
