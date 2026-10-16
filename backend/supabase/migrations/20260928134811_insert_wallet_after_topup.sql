CREATE OR REPLACE FUNCTION public.wallet_top_up()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status = 'Paid' AND OLD.status <> 'Paid' THEN
        UPDATE public.wallet
        SET balance = balance + NEW.amount
        WHERE id = NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER wallet_top_up_trigger
AFTER UPDATE OF status ON public.top_up_transactions
FOR EACH ROW
EXECUTE FUNCTION public.wallet_top_up();