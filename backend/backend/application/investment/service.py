from fastapi import Depends, FastAPI
from investment.schema import UserFundResponse,InvesmentReq,InvestmentResponse,FundDetailsReq,\
    InvestReq,InvestResponse,InvestedFundResponse,ShowBasedOn,FundDetailMonth,FundDetailYear,FundDetailsResponse,FundInvestmentResponse,ListFundInvestmentResponse,InvestmentDetailsResponse,UserInvestmentStatus,FarmerFundResponse,Status
from supabase import Client
import uuid
from investment.utils import is_owner,calculate_estimated_roi,build_fund_investment,get_area,parse_point,calculate_fund_total,calculate_withdrawable_amount
from user.service import get_full_name
from fastapi import HTTPException,UploadFile
from postgrest.exceptions import APIError
from collections import defaultdict
from datetime import datetime
from zoneinfo import ZoneInfo

import asyncio

async def get_fund(user_id:str,supabase:Client)->UserFundResponse:

    try:
        res = supabase.rpc(
            "get_investment_fund",
        {
            "user_id":user_id
        }
        ).execute()
        data = res.data or []
    except APIError as e:
        raise HTTPException(status_code=e.status, detail=str(e.code))
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail="something went wrong"
        )
    
    data = UserFundResponse(
            user_id=user_id,
            invested_fund=data["invested_fund"],
            wallet_balance=data["balance"]
        )
    return data

async def add_investment(investment_data:InvesmentReq,land_id:str,supabase:Client)->InvestmentResponse:
    try:
        investment_res = supabase.table("investment").insert({
                           "description":investment_data.description,
                           "status":investment_data.status,
                           "target_amount":investment_data.target_amount,
                           "estimated_selling_price":investment_data.estimated_selling_price,
                           "harvest_estimation":investment_data.harvest_estimation,
                           "land_id":land_id,
                           "commodity":investment_data.commodity,
                           "start_date": investment_data.plant_start.isoformat(),
                           "end_date":investment_data.plant_end.isoformat()
                            }).execute()
        investment_res = investment_res.data[0]
        response = InvestmentResponse(
                    id=investment_res["id"],
                    commodity=investment_res["commodity"],
                    description=investment_res["description"],
                    plant_start=investment_res["start_date"],
                    plant_end=investment_res["start_date"],
                    harvest_estimation= investment_res["harvest_estimation"],
                    estimated_selling_price=investment_res["estimated_selling_price"],
                    target_amount=investment_res["target_amount"],
                    status=investment_res["status"],
                    created_at=investment_res["created_at"]
        )
        return response
    except APIError as e:
        raise HTTPException(status_code=e.status, detail=str(e.code))
    except Exception as e:
        raise HTTPException(
                status_code=500,
                detail="something went wrong"
            )

async def invest(investment_id:str,user_id:str,invest_data:InvestReq,supabase:Client)->InvestResponse:
    try:
        if await is_owner(user_id=user_id,investment_id=investment_id,supabase=supabase):
            raise HTTPException(status_code=405,detail="you are not allowed to invest in this investment")

        investment_transaction = supabase.rpc(
                            "create_invest_transaction_record",
                            {"p_investor_id": user_id,"p_amount":invest_data.amount, "p_investment_id": investment_id},
                        ).execute()
        investment_res = investment_transaction.data
        response = InvestResponse(
            id = investment_res['id'],
            amount = investment_res['amount'],
            investment_id = investment_res['investment_id'],
            created_at = investment_res['created_at']
        )
        return response
    except APIError as e:
        raise HTTPException(status_code=e.status, detail=str(e.code))

    except HTTPException:
        raise

    except Exception as e:
        if "Insufficient wallet balance" in str(e):
            raise HTTPException(
                status_code=400,
                detail="Insufficient wallet balance"
            )
        raise HTTPException(
            status_code=500,
            detail="Failed to create investment transaction"
        )


async def get_invested_fund(
    based_on: ShowBasedOn,
    investor_id: str,
    supabase: Client
) -> InvestedFundResponse:

    try:
        wib = ZoneInfo("Asia/Jakarta")
        now = datetime.now(wib)

        query = (
            supabase
            .table("investment_transaction")
            .select("id, amount, created_at")
            .eq("investor_id", investor_id)
        )

        if based_on == ShowBasedOn.MONTHLY:

            start_date = datetime(
                now.year,
                1,
                1,
                tzinfo=wib
            )

            response = (
                query
                .gte("created_at", start_date.isoformat())
                .lte("created_at", now.isoformat())
                .execute()
            )

            monthly_amount = defaultdict(float)

            for item in response.data:
                date = datetime.fromisoformat(item["created_at"])

                month_key = date.strftime("%Y-%m")
                monthly_amount[month_key] += item["amount"]

            fund_details = []

            for month, amount in sorted(monthly_amount.items()):
                date = datetime.strptime(month, "%Y-%m")

                fund_details.append(
                    FundDetailMonth(
                        month=date.strftime("%B"),
                        amount=amount
                    )
                )

        else:

            response = query.execute()

            yearly_amount = defaultdict(float)

            for item in response.data:
                date = datetime.fromisoformat(item["created_at"])

                yearly_amount[date.year] += item["amount"]

            fund_details = []

            for year, amount in sorted(yearly_amount.items()):
                fund_details.append(
                    FundDetailYear(
                        year=year,
                        amount=amount
                    )
                )

        total_invested = sum(
            item.amount for item in fund_details
        )

        return InvestedFundResponse(
            investor_id=investor_id,
            total_invested=total_invested,
            fund_details=fund_details
        )

    except APIError as e:
        raise HTTPException(
            status_code=e.status,
            detail=str(e.code)
        )

async def add_fund_details(investment_id:str,user_id: str,fund_details:FundDetailsReq,supabase:Client)-> FundDetailsResponse:
    try:

        if not await is_owner(user_id=user_id,investment_id=investment_id,supabase=supabase):
            raise HTTPException(status_code=405,detail="you are not allowed to perform this action")


        query = supabase.table("investment").select("target_amount").eq("id", investment_id).execute()
        target_amount = query.data[0]['target_amount']
    
        total_amount = sum([fund_details.seedling,fund_details.fertilizer,fund_details.labour,fund_details.others or 0])
        if target_amount < total_amount:
            raise HTTPException(status_code=405,detail="total amount exceeds target")

        fund = supabase.table("fund_details").insert({"investment_id":investment_id,"seedling":fund_details.seedling,
                                                                "fertilizer":fund_details.fertilizer,"labour":fund_details.labour,
                                                                "others":fund_details.others,"description":fund_details.description}).execute()
        fund = fund.data[0]
        return FundDetailsResponse(
            investment_id=fund["investment_id"],
            seedling= fund["seedling"],
            fertilizer= fund["fertilizer"],
            labour= fund["labour"],
            others= fund["others"],
            description = fund["description"],
            total =total_amount
        )
        
    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
                    status_code=e.status,
                    detail=str(e.code)
                )

async def get_investment_on_status(
    user_id: str,
    investment_status: str,
    supabase: Client
)->ListFundInvestmentResponse:
    try:
        query = (
            supabase.table("investment")
            .select("""
                id,
                status,
                target_amount,
                commodity,
                start_date,
                end_date,
                harvest_estimation,
                estimated_selling_price,
                area!inner(farmer_id, name, area_images(image_url, sort_position)),
                investment_transaction(investor_id, amount),
                fund_details(seedling, fertilizer, others, labour)
            """)
            .eq("status", investment_status)
            .neq("area.farmer_id", user_id)
            .execute()
        )

        results = []

        for inv in query.data:
            transactions = inv.get("investment_transaction") or []

            total_invested = sum(
                t["amount"] or 0 for t in transactions
            )

            number_of_investors = len(transactions)
            fund_details = inv.get("fund_details") or []
            if isinstance(fund_details, dict):
                fund_details = [fund_details]

            estimated_cost = sum(
                (fd.get(field) or 0)
                for fd in fund_details
                for field in ("seedling", "fertilizer", "others", "labour")
            )


            roi = None

            if estimated_cost > 0:
                roi_result = calculate_estimated_roi(
                    estimated_harvest=inv["harvest_estimation"],
                    estimated_selling_price=inv["estimated_selling_price"],
                    estimated_cost=estimated_cost,
                )
                roi = roi_result["projected_roi"]

            area = inv.get("area") or {}
            if isinstance(area, list):
                area = area[0] if area else {}
            area_images = sorted(
                area.get("area_images") or [],
                key=lambda img: img.get("sort_position") if img.get("sort_position") is not None else 0,
            )
            images = [img["image_url"] for img in area_images if img.get("image_url")]

            response = FundInvestmentResponse(
                id=inv["id"],
                commodity=inv["commodity"],
                status=inv["status"],
                number_of_investors=number_of_investors,
                end_date=inv["end_date"],
                target_amount=inv["target_amount"],
                collected_amount=total_invested,
                roi=roi,
                area_name=area.get("name"),
                images=images,
            )



            results.append(response)

        return ListFundInvestmentResponse(investments=results)

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e),
        )


async def get_investment_details(
    investment_id: str,
    supabase: Client
)->InvestmentDetailsResponse:
    try:
        query = (
            supabase.table("investment")
            .select("""
                id,
                status,
                description,
                target_amount,
                commodity,
                start_date,
                end_date,
                harvest_estimation,
                estimated_selling_price,
                area!inner(farmer_id, name, location, area_images(image_url, sort_position)),
                investment_transaction(investor_id, amount),
                fund_details(seedling, fertilizer, others, labour)
            """)
            .eq("id", investment_id)
            .limit(1)
            .execute()
        )

        if not query.data:
            raise HTTPException(status_code=404, detail="Investment not found")

        inv = query.data[0]
        area = get_area(inv)

        creator_name = None
        if area.get("farmer_id"):
            try:
                creator_name = (await get_full_name(user_id=area["farmer_id"], supabase=supabase)).full_name
            except HTTPException as e:
                if e.status_code != 404:
                    raise

        point = parse_point(area.get("location"))
        latitude, longitude = point if point else (None, None)

        return InvestmentDetailsResponse(
            **build_fund_investment(inv).model_dump(),
            description=inv["description"],
            creator_name=creator_name,
            latitude=latitude,
            longitude=longitude,
        )

    except HTTPException:
        raise

    except Exception:
        raise HTTPException(
            status_code=500,
            detail="something went wrong",
        )


async def get_fund_details(
    investment_id: str,
    supabase: Client
)->FundDetailsResponse:
    try:
        query = (
            supabase.table("fund_details")
            .select("investment_id, seedling, fertilizer, labour, others, description")
            .eq("investment_id", investment_id)
            .limit(1)
            .execute()
        )

        if not query.data:
            raise HTTPException(status_code=404, detail="Fund details not found")

        fund = query.data[0]
        return FundDetailsResponse(
            investment_id=fund["investment_id"],
            seedling=fund["seedling"],
            fertilizer=fund["fertilizer"],
            labour=fund["labour"],
            others=fund["others"],
            description=fund["description"],
            total=calculate_fund_total(fund),
        )

    except HTTPException:
        raise

    except Exception:
        raise HTTPException(
            status_code=500,
            detail="something went wrong",
        )


async def get_user_investments(
    user_id: str,
    investment_status: UserInvestmentStatus,
    supabase: Client
)->ListFundInvestmentResponse:
    try:
        # 1. which investments did this user put money into
        transactions = (
            supabase.table("investment_transaction")
            .select("investment_id")
            .eq("investor_id", user_id)
            .execute()
        )
        investment_ids = list({t["investment_id"] for t in transactions.data})

        if not investment_ids:
            return ListFundInvestmentResponse(investments=[])

        # 2. fetch those investments with all of their transactions,
        #    so number_of_investors and collected_amount cover every investor
        query = (
            supabase.table("investment")
            .select("""
                id,
                status,
                target_amount,
                commodity,
                start_date,
                end_date,
                harvest_estimation,
                estimated_selling_price,
                area(farmer_id, name, area_images(image_url, sort_position)),
                investment_transaction(investor_id, amount),
                fund_details(seedling, fertilizer, others, labour)
            """)
            .in_("id", investment_ids)
            .eq("status", investment_status.value)
            .execute()
        )

        return ListFundInvestmentResponse(
            investments=[build_fund_investment(inv) for inv in query.data]
        )

    except HTTPException:
        raise

    except Exception:
        raise HTTPException(
            status_code=500,
            detail="something went wrong",
        )


async def get_farmer_fund(
    user_id: str,
    supabase: Client
)->FarmerFundResponse:
    try:
        wallet = (
            supabase.table("wallet")
            .select("balance")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )
        if not wallet.data:
            raise HTTPException(status_code=404, detail="Wallet not found")

        investments = (
            supabase.table("investment")
            .select("""
                status,
                target_amount,
                area!inner(farmer_id),
                investment_transaction(amount)
            """)
            .eq("area.farmer_id", user_id)
            .execute()
        )

        return FarmerFundResponse(
            user_id=user_id,
            amount_to_withdraw=calculate_withdrawable_amount(investments.data),
            wallet_balance=wallet.data[0]["balance"],
        )

    except HTTPException:
        raise

    except Exception:
        raise HTTPException(
            status_code=500,
            detail="something went wrong",
        )


async def get_farmer_investments(
    user_id: str,
    investment_status: UserInvestmentStatus,
    supabase: Client
)->ListFundInvestmentResponse:
    try:
        # investments created by this farmer, i.e. on areas owned by the farmer
        query = (
            supabase.table("investment")
            .select("""
                id,
                status,
                target_amount,
                commodity,
                start_date,
                end_date,
                harvest_estimation,
                estimated_selling_price,
                area!inner(farmer_id, name, area_images(image_url, sort_position)),
                investment_transaction(investor_id, amount),
                fund_details(seedling, fertilizer, others, labour)
            """)
            .eq("area.farmer_id", user_id)
            .eq("status", investment_status.value)
            .execute()
        )

        return ListFundInvestmentResponse(
            investments=[build_fund_investment(inv) for inv in query.data]
        )

    except HTTPException:
        raise

    except Exception:
        raise HTTPException(
            status_code=500,
            detail="something went wrong",
        )
