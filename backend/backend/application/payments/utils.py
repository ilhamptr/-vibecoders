from fastapi import FastAPI, Header, HTTPException, Depends, status
from dotenv import load_dotenv
import os

EXPECTED_CALLBACK_TOKEN = os.getenv("XENDIT_WEBHOOK_TOKEN")


async def verify_callback_token(x_callback_token: str = Header(None)):
    """
    FastAPI automatically maps the 'X-Callback-Token' HTTP header 
    to the 'x_callback_token' parameter.
    """
    if x_callback_token is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing X-Callback-Token header"
        )
    
    if x_callback_token != EXPECTED_CALLBACK_TOKEN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid X-Callback-Token"
        )
        
    return x_callback_token
