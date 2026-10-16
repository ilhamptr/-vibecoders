CREATE OR REPLACE FUNCTION public.check_investment_owner(
  p_user_id uuid,
  p_investment_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.investment i
    JOIN public.area l ON l.id = i.land_id
    WHERE i.id = p_investment_id
      AND l.farmer_id = p_user_id
  );
$$;