CREATE OR REPLACE FUNCTION public.create_area_with_images(
    p_area_id uuid,
    p_area_name text,
    p_area_description text,
    p_area_width float,
    p_area_address text,
    p_area_latitude double precision,
    p_area_longitude double precision,
    p_images jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_area public.area;
BEGIN

    -- 1. Insert area
    INSERT INTO public.area (
        id,
        name,
        address,
        description,
        area_width,
        location,
        farmer_id
    )
    VALUES (
        p_area_id,
        p_area_name,
        p_area_address,
        p_area_description,
        p_area_width,
        ST_SetSRID(
            ST_MakePoint(
                p_area_longitude,
                p_area_latitude
            ),
            4326
        )::geography,
        auth.uid()
    )
    RETURNING * INTO v_area;


    -- 2. Insert images
    INSERT INTO public.area_images (
        area_id,
        image_url,
        sort_position
    )
    SELECT
        v_area.id,
        image->>'image_url',
        (image->>'sort_position')::integer
    FROM jsonb_array_elements(p_images) AS image;


    -- 3. Return area + coordinates
    RETURN jsonb_build_object(
        'id', v_area.id,
        'name', v_area.name,
        'address', v_area.address,
        'description', v_area.description,
        'area_width', v_area.area_width,
        'created_at', v_area.created_at,
        'latitude', p_area_latitude,
        'longitude', p_area_longitude,
        'farmer_id', v_area.farmer_id
    );

END;
$$;