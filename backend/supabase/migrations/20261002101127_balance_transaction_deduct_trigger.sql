CREATE OR REPLACE FUNCTION public.balance_transaction_record_investment()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.balance_transaction (reference_id,amount,reference_type) VALUES (NEW.id,NEW.amount,'Invested');
    RETURN NEW;
END;
$$;

CREATE TRIGGER record_balance_deduct
AFTER INSERT ON public.investment_transaction
FOR EACH ROW
EXECUTE FUNCTION public.balance_transaction_record_investment();