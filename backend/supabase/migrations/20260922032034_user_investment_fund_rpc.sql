CREATE OR REPLACE FUNCTION public.get_investment_fund(
  user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_invest_fund public.investment_transaction;
    v_wallet public.wallet;
BEGIN

    -- 1. selecting invested fund
    SELECT id, investment_id, created_at, amount, investor_id
    INTO v_invest_fund
    FROM public.investment_transaction
    WHERE investor_id = user_id;

    -- 2. selecting investor's wallet
    SELECT id, created_at, balance
    INTO v_wallet
    FROM public.wallet
    WHERE id = user_id;

    RETURN jsonb_build_object(
        'user_id', user_id,
        'balance', v_wallet.balance,
        'invested_fund', v_invest_fund.amount,
        'investment_id', v_invest_fund.investment_id
    );
END;
$$;



CREATE OR REPLACE FUNCTION public.get_investment_fund(
  user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_total_invested numeric;
    v_wallet public.wallet;
BEGIN

    -- 1. sum of all invested funds
    SELECT COALESCE(SUM(amount), 0)
    INTO v_total_invested
    FROM public.investment_transaction
    WHERE investor_id = user_id;

    -- 2. selecting investor's wallet
    SELECT id, created_at, balance
    INTO v_wallet
    FROM public.wallet
    WHERE id = user_id;

    RETURN jsonb_build_object(
        'user_id', user_id,
        'balance', v_wallet.balance,
        'invested_fund', v_total_invested
    );
END;
$$;