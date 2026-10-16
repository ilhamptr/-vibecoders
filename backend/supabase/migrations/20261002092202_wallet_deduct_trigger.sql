CREATE OR REPLACE FUNCTION public.deduct_wallet_balance()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN

    UPDATE public.wallet
    SET balance = balance - NEW.amount
    WHERE id = NEW.investor_id
      AND balance >= NEW.amount;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Insufficient wallet balance';
    END IF;

    RETURN NEW;

END;
$$;
CREATE TRIGGER after_investment_transaction_created
AFTER INSERT ON public.investment_transaction
FOR EACH ROW
EXECUTE FUNCTION public.deduct_wallet_balance();