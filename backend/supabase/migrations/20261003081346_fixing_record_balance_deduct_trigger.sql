DROP TRIGGER IF EXISTS record_balance_deduct
ON public.investment_transaction;

DROP FUNCTION IF EXISTS public.balance_transaction_record_investment();

CREATE OR REPLACE FUNCTION public.balance_transaction_record_investment()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.balance_transaction (investment_transaction_id,amount,reference_type) VALUES (NEW.id,NEW.amount,'Invested');
    RETURN NEW;
END;
$$;

CREATE TRIGGER record_balance_deduct
AFTER INSERT ON public.investment_transaction
FOR EACH ROW
EXECUTE FUNCTION public.balance_transaction_record_investment();