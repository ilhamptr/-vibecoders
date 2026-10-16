CREATE OR REPLACE FUNCTION move_invested_fund(
    p_investment_id UUID
)
RETURNS NUMERIC
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
    v_farmer_id UUID;
    v_status TEXT;
    v_total_invested NUMERIC;
BEGIN
    -- 1. Fetch the investment and its farmer, and lock the investment row
    --    so concurrent calls for the same investment run one at a time
    SELECT a.farmer_id, i.status
    INTO v_farmer_id, v_status
    FROM investment i
    JOIN area a ON a.id = i.land_id
    WHERE i.id = p_investment_id
    FOR UPDATE OF i;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Investment not found';
    END IF;

    -- 2. Reject if the fund was already transferred or the investment is completed
    IF v_status IN ('Dana Sudah Ditransfer', 'Selesai') THEN
        RAISE EXCEPTION 'Investment status is %, fund cannot be moved', v_status;
    END IF;

    -- 3. Make sure the area has an owner (farmer)
    IF v_farmer_id IS NULL THEN
        RAISE EXCEPTION 'Farmer not found for this investment';
    END IF;

    -- 4. Calculate the total amount invested in this investment
    SELECT COALESCE(SUM(amount), 0)
    INTO v_total_invested
    FROM investment_transaction
    WHERE investment_id = p_investment_id;

    IF v_total_invested <= 0 THEN
        RAISE EXCEPTION 'No invested fund found';
    END IF;

    -- 5. Add the total invested amount to the farmer's wallet
    UPDATE wallet
    SET balance = balance + v_total_invested
    WHERE id = v_farmer_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Farmer wallet not found';
    END IF;

    -- 6. Mark the investment as transferred to prevent a second transfer
    UPDATE investment
    SET status = 'Dana Sudah Ditransfer'
    WHERE id = p_investment_id;

    -- 7. Return the amount that was moved
    RETURN v_total_invested;
END;
$$;