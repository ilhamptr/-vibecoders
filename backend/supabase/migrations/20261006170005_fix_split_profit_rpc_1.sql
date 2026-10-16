CREATE OR REPLACE FUNCTION distribute_profit(
    p_investment_id UUID,
    p_profit_amount NUMERIC
)
RETURNS TABLE (
    investor_id UUID,
    invested_amount NUMERIC,
    profit_amount NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_farmer_id UUID;
    v_farmer_balance NUMERIC;
    v_total_invested NUMERIC;
BEGIN

    -- 1. Validate profit amount
    IF p_profit_amount <= 0 THEN
        RAISE EXCEPTION 'Profit amount must be greater than 0';
    END IF;


    -- 2. Get farmer through investment -> area
    -- Lock investment to prevent concurrent distribution
    SELECT a.farmer_id
    INTO v_farmer_id
    FROM investment i
    JOIN area a ON a.id = i.land_id
    WHERE i.id = p_investment_id
    AND i.status != 'Selesai'
    FOR UPDATE OF i;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Investment not found or already completed';
    END IF;

    IF v_farmer_id IS NULL THEN
        RAISE EXCEPTION 'Farmer not found for this investment';
    END IF;


    -- 3. Lock farmer wallet
    SELECT balance
    INTO v_farmer_balance
    FROM wallet
    WHERE id = v_farmer_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Farmer wallet not found';
    END IF;


    -- 4. Check farmer balance
    IF v_farmer_balance < p_profit_amount THEN
        RAISE EXCEPTION 'Insufficient farmer wallet balance';
    END IF;


    -- 5. Get total invested capital
    SELECT COALESCE(SUM(amount), 0)
    INTO v_total_invested
    FROM investment_transaction
    WHERE investment_id = p_investment_id;

    IF v_total_invested <= 0 THEN
        RAISE EXCEPTION 'No investment capital found';
    END IF;


    -- 6. Deduct profit from farmer wallet
    UPDATE wallet
    SET balance = balance - p_profit_amount
    WHERE id = v_farmer_id;


    -- 7. Calculate and distribute profit
    RETURN QUERY
    WITH investor_investments AS (
        SELECT
            it.investor_id,
            SUM(it.amount) AS invested_amount
        FROM investment_transaction it
        WHERE it.investment_id = p_investment_id
        GROUP BY it.investor_id
    ),

    calculated_profit AS (
        SELECT
            ii.investor_id,
            ii.invested_amount,
            ROUND(
                (
                    ii.invested_amount / v_total_invested
                ) * p_profit_amount,
                2
            ) AS profit_amount
        FROM investor_investments ii
    ),

    updated_wallets AS (
        UPDATE wallet w
        SET balance = w.balance + cp.profit_amount
        FROM calculated_profit cp
        WHERE w.id = cp.investor_id
        RETURNING
            cp.investor_id,
            cp.invested_amount,
            cp.profit_amount
    )

    SELECT
        uw.investor_id,
        uw.invested_amount,
        uw.profit_amount
    FROM updated_wallets uw;

    -- 8. Mark investment as completed
    UPDATE investment
    SET status = 'Selesai'
    WHERE id = p_investment_id;

END;
$$;
