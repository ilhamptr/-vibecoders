from supabase import create_client,Client
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from dotenv import load_dotenv
import os

load_dotenv()

# for fetching Authorization Bearer on header
security = HTTPBearer()



def get_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    return credentials.credentials

def get_authenticated_supabase(token: str = Depends(get_token)) -> Client:
    client = create_client(os.getenv("SUPABASE_URL"),os.getenv("SUPABASE_SECRET"))
    client.postgrest.auth(token) 
    # Keep the caller JWT on Storage requests too. PostgREST auth alone does
    # not replace the Authorization header used by storage3, so without this
    # Storage RLS would see the service key instead of the logged-in user.
    client.storage._headers["Authorization"] = f"Bearer {token}"
    return client

async def get_current_user(
    token: str = Depends(get_token),
    supabase: Client = Depends(get_authenticated_supabase),
):
    try:
        res = supabase.auth.get_user(token)
        return res.user
    except Exception as e:
        error_msg = str(e).lower()
        if "expired" in error_msg:
            raise HTTPException(status_code=401, detail="Expired token")
        raise HTTPException(status_code=401, detail="Invalid token")


def get_supabase() -> Client:
    client = create_client(os.getenv("SUPABASE_URL"),os.getenv("SUPABASE_SECRET"))
    return client


