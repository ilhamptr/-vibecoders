CREATE OR REPLACE FUNCTION public.balance_transaction_record()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status = 'Paid' AND OLD.status <> 'Paid' THEN
        INSERT INTO public.balance_transaction (reference_id,amount,reference_type) VALUES (NEW.id,NEW.amount,'Top Up');
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER record_balance_topup
AFTER UPDATE OF status ON public.top_up_transactions
FOR EACH ROW
EXECUTE FUNCTION public.balance_transaction_record();