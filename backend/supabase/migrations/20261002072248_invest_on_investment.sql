CREATE OR REPLACE FUNCTION public.create_invest_transaction_record(
    p_investment_id uuid,
    p_amount numeric,
    p_investor_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_transaction public.investment_transaction;

    v_target_amount numeric;
    v_current_amount numeric;
BEGIN

    SELECT target_amount
    INTO v_target_amount
    FROM public.investment 
    WHERE id = p_investment_id
    FOR UPDATE;

    IF v_target_amount IS NULL THEN
        RAISE EXCEPTION 'Investment Not Found';
    END IF;

    IF p_amount <=0 THEN
        RAISE EXCEPTION 'Investment Amount cannot be  0';
    END IF;


    SELECT COALESCE(SUM(amount),0)
    INTO v_current_amount
    FROM public.investment_transaction
    WHERE investment_id = p_investment_id;

    IF v_current_amount + p_amount > v_target_amount THEN
        RAISE EXCEPTION 'Investment target exceeded';
    END IF;


    INSERT INTO public.investment_transaction (
        investment_id,
        amount,
        investor_id
    )
    VALUES(
        p_investment_id,
        p_amount,
        p_investor_id
    )

    RETURNING * INTO v_transaction;

    RETURN to_jsonb(
        v_transaction
    );

END;
$$;