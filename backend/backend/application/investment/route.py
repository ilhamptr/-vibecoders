
from fastapi import APIRouter
from dependencies.supabase import get_supabase,get_authenticated_supabase,get_current_user
from fastapi import Depends,UploadFile,Form,File,Body
from typing import Annotated
from investment.service import get_fund,add_investment,invest,get_invested_fund,add_fund_details,get_investment_on_status,get_investment_details,get_fund_details,get_user_investments,get_farmer_fund,get_farmer_investments
from investment.schema import UserFundResponse,InvesmentReq,InvestmentResponse,InvestReq,InvestResponse,InvestedFundResponse,ShowBasedOn,FundDetailsReq,FundDetailsResponse,ListFundInvestmentResponse,InvestmentDetailsResponse,UserInvestmentStatus,FarmerFundResponse,Status



router = APIRouter(
    prefix="/investment",
    tags=["investment"],
    # dependencies=[Depends(get_current_user),Depends(get_supabase)],
    responses={404: {"description": "Not found"}},
)


@router.get("/investment-fund",status_code = 200)
async def investment_fund(
                        current_user=Depends(get_current_user),
                        supabase=Depends(get_authenticated_supabase))->UserFundResponse:

    user_id=str(current_user.id)
    response = await get_fund(user_id=user_id,supabase=supabase)
    return response


@router.post("/create-investment/{land_id}",status_code=201)
async def create_investment(
                            investment_data:InvesmentReq,
                            land_id: str,
                            current_user=Depends(get_current_user),
                            supabase=Depends(get_authenticated_supabase))->InvestmentResponse:
    response = await add_investment(investment_data=investment_data,land_id=land_id,supabase=supabase)
    return response

@router.post("/invest/{investment_id}",status_code=201)
async def invest_investment(
                            invest_data:InvestReq,
                            investment_id: str,
                            current_user=Depends(get_current_user),
                            supabase=Depends(get_authenticated_supabase))->InvestResponse:
    user_id=str(current_user.id)
    response = await invest(investment_id=investment_id,user_id=user_id,invest_data=invest_data,supabase=supabase)
    return response


@router.post("/user-invested-fund",status_code=200)
async def user_invested_fund( 
                            based_on: ShowBasedOn,
                            current_user=Depends(get_current_user),
                            supabase=Depends(get_authenticated_supabase))->InvestedFundResponse:
    user_id = str(current_user.id)
    response = await get_invested_fund(based_on=based_on,investor_id=user_id,supabase=supabase)
    return response

@router.post("/investment-fund-details/{investment_id}",status_code=201)
async def investment_fund_details( 
                            investment_id:str,
                            fund_details:FundDetailsReq,
                            current_user=Depends(get_current_user),
                            supabase=Depends(get_authenticated_supabase))->FundDetailsResponse:
    user_id = str(current_user.id)
    response = await add_fund_details(investment_id=investment_id,user_id=user_id,fund_details=fund_details,supabase=supabase)
    return response



@router.get("/get-active-investment",status_code = 200)
async def get_investments(
                        current_user=Depends(get_current_user),
                        supabase=Depends(get_authenticated_supabase)
                        )->ListFundInvestmentResponse:
    user_id = str(current_user.id)
    response = await get_investment_on_status(user_id=user_id,investment_status=Status.ACTIVE.value,supabase=supabase)
    return response
    


@router.get("/get-investment-details/{investment_id}",status_code = 200)
async def investment_details(
                        investment_id: str,
                        current_user=Depends(get_current_user),
                        supabase=Depends(get_authenticated_supabase)
                        )->InvestmentDetailsResponse:
    response = await get_investment_details(investment_id=investment_id,supabase=supabase)
    return response


@router.get("/investment-fund-details/{investment_id}",status_code = 200)
async def get_investment_fund_details(
                        investment_id: str,
                        current_user=Depends(get_current_user),
                        supabase=Depends(get_authenticated_supabase)
                        )->FundDetailsResponse:
    response = await get_fund_details(investment_id=investment_id,supabase=supabase)
    return response


@router.get("/get-user-investments",status_code = 200)
async def user_investments(
                        investment_status: UserInvestmentStatus,
                        current_user=Depends(get_current_user),
                        supabase=Depends(get_authenticated_supabase)
                        )->ListFundInvestmentResponse:
    user_id = str(current_user.id)
    response = await get_user_investments(user_id=user_id,investment_status=investment_status,supabase=supabase)
    return response


@router.get("/get-farmer-fund",status_code = 200)
async def farmer_fund(
                        current_user=Depends(get_current_user),
                        supabase=Depends(get_authenticated_supabase)
                        )->FarmerFundResponse:
    user_id = str(current_user.id)
    response = await get_farmer_fund(user_id=user_id,supabase=supabase)
    return response


@router.get("/get-farmers-investments",status_code = 200)
async def farmers_investments(
                        investment_status: UserInvestmentStatus,
                        current_user=Depends(get_current_user),
                        supabase=Depends(get_authenticated_supabase)
                        )->ListFundInvestmentResponse:
    user_id = str(current_user.id)
    response = await get_farmer_investments(user_id=user_id,investment_status=investment_status,supabase=supabase)
    return response
