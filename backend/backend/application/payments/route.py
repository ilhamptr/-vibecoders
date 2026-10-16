from fastapi import APIRouter,Depends,Request,HTTPException,status
from dependencies.supabase import get_supabase,get_authenticated_supabase,get_current_user
from typing import Annotated
from payments.schema import TopUpRequest,TopUpRes,ProfitResponse,ProfitReq,TransferFundRes
from payments.service import wallet_top_up,handle_webhook,split_profit,tranfer_investor_fund
import os
import json
from payments.utils import verify_callback_token

router = APIRouter(
    prefix="/payment",
    tags=["payment"],
    # dependencies=[Depends(get_current_user),Depends(get_supabase)],
    responses={404: {"description": "Not found"}},
)


@router.post("/top-up-wallet",status_code=200)
async def top_up(top_up_data:TopUpRequest,
                 current_user=Depends(get_current_user),
                 supabase=Depends(get_authenticated_supabase))->TopUpRes:
    user_id = str(current_user.id)
    response = await wallet_top_up(top_up_data=top_up_data,
                                   user_id=user_id,
                                   user_name=current_user.email,
                                   user_email=current_user.email,
                                   supabase=supabase)
    return response


@router.post("/webhook/verify",status_code=200)
async def webhook_payment(
                request: Request,
                callback_token=Depends(verify_callback_token),
                supabase=Depends(get_supabase)
):
    payload = await request.body()
    try:
        data = json.loads(payload)
    except json.JSONDecodeError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Invalid JSON payload"
        )

    response = await handle_webhook(body=data,supabase=supabase)
    return {"data":"berhasil"}


@router.post("/distribute-profit/{investment_id}",status_code = 200)
async def split_investment_profit(
                investment_id:str,
                profit_data:ProfitReq,
                current_user=Depends(get_current_user),
                supabase=Depends(get_authenticated_supabase))->ProfitResponse:

    user_id = str(current_user.id)
    response = await split_profit(farmer_id=user_id,profit_data=profit_data,investment_id=investment_id,supabase=supabase)
    return response

@router.post("/transfer-investor-funds/{investment_id}",status_code = 200)
async def move_fund(
                    investment_id:str,
                    current_user=Depends(get_current_user),
                    supabase=Depends(get_authenticated_supabase))->TransferFundRes:
    user_id = str(current_user.id)
    response = await tranfer_investor_fund(farmer_id=user_id,investment_id=investment_id,supabase=supabase)
    return response