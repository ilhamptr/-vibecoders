-- Migration: RPC functions for area list and detail
-- Non-destructive: CREATE OR REPLACE only

-- ── 1. List all active areas owned by a farmer ──────────────────────────────
CREATE OR REPLACE FUNCTION public.get_areas_by_farmer(p_farmer_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_result jsonb;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'id',         a.id,
            'name',       a.name,
            'address',    a.address,
            'area_width', a.area_width,
            'latitude',   ST_Y(a.location::geometry),
            'longitude',  ST_X(a.location::geometry),
            'created_at', a.created_at,
            'farmer_id',  a.farmer_id
        )
    )
    INTO v_result
    FROM public.area a
    WHERE a.farmer_id = p_farmer_id
      AND a.deleted_at IS NULL;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;


-- ── 2. Get single area detail with images ────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_area_detail(p_area_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_area   public.area;
    v_images jsonb;
BEGIN
    SELECT * INTO v_area
    FROM public.area
    WHERE id = p_area_id
      AND deleted_at IS NULL;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'id',            ai.id,
                'image_url',     ai.image_url,
                'sort_position', ai.sort_position
            )
            ORDER BY ai.sort_position
        ),
        '[]'::jsonb
    )
    INTO v_images
    FROM public.area_images ai
    WHERE ai.area_id = p_area_id;

    RETURN jsonb_build_object(
        'id',          v_area.id,
        'name',        v_area.name,
        'address',     v_area.address,
        'description', v_area.description,
        'area_width',  v_area.area_width,
        'latitude',    ST_Y(v_area.location::geometry),
        'longitude',   ST_X(v_area.location::geometry),
        'created_at',  v_area.created_at,
        'farmer_id',   v_area.farmer_id,
        'images',      v_images
    );
END;
$$;
