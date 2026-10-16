create function public.wallet_creation()
RETURNS trigger 
LANGUAGE plpgsql 
AS $$

begin

    insert into public.wallet(id,balance) values(new.id,0);
    return new;
end;
$$;

create trigger wallet_creation_trigger
after INSERT on public.shared_profile
for each row
execute function wallet_creation();
