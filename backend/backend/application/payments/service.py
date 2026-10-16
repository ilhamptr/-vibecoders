from fastapi import Depends, FastAPI
from payments.schema import TopUpRequest,TopUpRes,ProfitResponse,ProfitReq,TransferFundRes
from supabase import Client
from investment.service import is_owner
import uuid
from user.utils import validate_file_size
from fastapi import HTTPException,UploadFile
from postgrest.exceptions import APIError
import asyncio
import requests
from datetime import UTC,datetime

import os
from dotenv import load_dotenv
import uuid



load_dotenv()


async def wallet_top_up(top_up_data: TopUpRequest, user_id: str, user_name: str, user_email: str, supabase: Client) -> TopUpRes:
    xendit_endpoint = f"{os.getenv('BASE_XENDIT_URL')}/sessions"
    reference_id = f'trs-topup-{user_id}-{uuid.uuid4().hex[:8]}'
    secret_key = os.getenv("XENDIT_SECRET_KEY")

    payload = {
        'reference_id': reference_id,
        'session_type': 'PAY',
        'mode': 'PAYMENT_LINK',
        'currency': 'IDR',
        'amount': top_up_data.amount,
        'country': 'ID',
        'customer': {
            'reference_id': f'cust-{user_id}-{uuid.uuid4().hex[:6]}',  # unik tiap transaksi
            'type': 'INDIVIDUAL',
            'email': user_email,
            'individual_detail': {'given_names': user_name}
        },
        'description': f'Top up saldo - {reference_id}',
        'success_return_url': 'https://tani-app.com/topup/success',
        'cancel_return_url': 'https://tani-app.com/topup/cancel'
    }

    try:
        supabase.table("top_up_transactions").insert({
            "user_id": user_id,
            "order_id": reference_id,
            "amount": top_up_data.amount,
            "status": "Pending"
        }).execute()
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to create top up")

    session_response = None
    try:
        session_response = requests.post(xendit_endpoint, auth=(secret_key, ''), json=payload)
        session_response.raise_for_status()
        session = session_response.json()
        supabase.table("top_up_transactions").update({
            "transaction_id": session['payment_session_id'],
            "payment_link_url": session['payment_link_url']
        }).eq("order_id", reference_id).execute()

        return TopUpRes(
            reference_id=session['reference_id'],
            payment_link_url=session['payment_link_url'],
            status="Pending"
        )
    except Exception as e:
        if session_response is not None:
            pass
        supabase.table("top_up_transactions").update({"status": "Failed"}).eq("order_id", reference_id).execute()
        raise HTTPException(status_code=500, detail="Failed to create payment")

async def handle_webhook(body:dict,supabase:Client):

    if body['event'] == 'payment_session.completed':
        data = body['data']
        reference_id = data['reference_id']
        try:
            supabase.table("top_up_transactions").update({
                        "paid_at": datetime.now(UTC).isoformat(),
                        "status": "Paid"
                    }).eq("order_id", reference_id).execute()
            return 
        except  Exception as e:
            raise HTTPException(status_code=500, detail="payment failed to be recorded")
    return


async def split_profit(farmer_id:str,profit_data:ProfitReq,investment_id:str,supabase:Client)->ProfitResponse:
    try:
        if not await is_owner(user_id=farmer_id,investment_id=investment_id,supabase=supabase):
            raise HTTPException(status_code=405,detail="you are not allowed to perform this action")

        res = supabase.rpc(
            "distribute_profit",
        {
            "p_investment_id":investment_id,
            "p_profit_amount":profit_data.amount
        }
        ).execute()
        # data = res.data or []


        response = ProfitResponse(
            message="Keuntungan Berhasil dibagikan"
        )
        return response
    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
                    status_code=e.status,
                    detail=str(e.code)
                )


async def tranfer_investor_fund(farmer_id:str,investment_id:str,supabase:Client)->TransferFundRes:
    try:
        if not await is_owner(user_id=farmer_id,investment_id=investment_id,supabase=supabase):
            raise HTTPException(status_code=405,detail="you are not allowed to perform this action")

        res = supabase.rpc(
            "move_invested_fund",
        {
            "p_investment_id":investment_id,
        }
        ).execute()
        # data = res.data or []


        response = TransferFundRes(
            message="Dana Berhasil dipindahkan ke akun farmer"
        )
        return response

    except HTTPException:
            raise
    
    except Exception as e:
        raise HTTPException(
                status_code=e.status,
                detail=str(e.code)
            )