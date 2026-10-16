import struct

from supabase import Client
from postgrest.exceptions import APIError
from investment.schema import FundInvestmentResponse


def calculate_estimated_roi(
    estimated_harvest: float,
    estimated_selling_price: float,
    estimated_cost: float,
) -> dict:
    if estimated_harvest < 0:
        raise ValueError("Estimated harvest cannot be negative")

    if estimated_selling_price < 0:
        raise ValueError("Estimated selling price cannot be negative")

    if estimated_cost <= 0:
        raise ValueError("Estimated cost must be greater than zero")

    projected_revenue = estimated_harvest * estimated_selling_price
    projected_profit = projected_revenue - estimated_cost
    projected_roi = (projected_profit / estimated_cost) * 100

    return {
        "projected_revenue": projected_revenue,
        "projected_profit": projected_profit,
        "projected_roi": round(projected_roi, 2),
    }

async def is_owner(user_id:str,investment_id:str,supabase:Client)->bool:
    try:
        response = supabase.rpc(
            "check_investment_owner",
            {"p_user_id": user_id, "p_investment_id": investment_id},
        ).execute()
    except APIError as e:
        raise RuntimeError(f"Failed to call RPC: {e.message}") from e

    return response.data is True


# async def check_fund_limit(investment_id:str,user_id:str,amount:float,supabase:Client)->bool:
#     try:
#         response = supabase.rpc(
#                     "create_invest_transaction_record",
#                     {"p_investor_id": user_id,"p_amount":amount, "p_investment_id": investment_id},
#                 ).execute()
#     except APIError as e:
#             raise RuntimeError(f"RPC gagal: {e.message}") from e
        
#     return response.data is True
        


def get_area(inv: dict) -> dict:
    """Return the embedded area of an investment row (PostgREST may give a dict or a list)."""
    area = inv.get("area") or {}
    if isinstance(area, list):
        area = area[0] if area else {}
    return area


def parse_point(value) -> tuple[float, float] | None:
    """Return (latitude, longitude) from a PostGIS point as returned by PostgREST.

    Supports GeoJSON (dict), WKT ("POINT(lon lat)", optionally with "SRID=...;")
    and EWKB hex, which is PostgREST's default output for geometry/geography columns.
    Returns None if the value is empty or cannot be parsed.
    """
    if not value:
        return None

    try:
        if isinstance(value, dict):
            lon, lat = value["coordinates"][:2]
            return float(lat), float(lon)

        text = str(value).strip()
        if text.upper().startswith("SRID="):
            text = text.split(";", 1)[1]

        if text.upper().startswith("POINT"):
            lon, lat = text[text.index("(") + 1:text.index(")")].split()[:2]
            return float(lat), float(lon)

        raw = bytes.fromhex(text)
        endian = "<" if raw[0] == 1 else ">"
        wkb_type = struct.unpack(endian + "I", raw[1:5])[0]
        offset = 5
        if wkb_type & 0x20000000:  # SRID is embedded in EWKB
            offset += 4
        lon, lat = struct.unpack(endian + "dd", raw[offset:offset + 16])
        return lat, lon
    except Exception:
        return None


def build_fund_investment(inv: dict) -> FundInvestmentResponse:
    """Map an investment row (with area, transactions and fund_details embedded) to FundInvestmentResponse."""
    transactions = inv.get("investment_transaction") or []
    total_invested = sum(t["amount"] or 0 for t in transactions)

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
        roi = calculate_estimated_roi(
            estimated_harvest=inv["harvest_estimation"],
            estimated_selling_price=inv["estimated_selling_price"],
            estimated_cost=estimated_cost,
        )["projected_roi"]

    area = get_area(inv)
    area_images = sorted(
        area.get("area_images") or [],
        key=lambda img: img.get("sort_position") if img.get("sort_position") is not None else 0,
    )

    return FundInvestmentResponse(
        id=inv["id"],
        commodity=inv["commodity"],
        status=inv["status"],
        number_of_investors=len(transactions),
        end_date=inv["end_date"],
        target_amount=inv["target_amount"],
        collected_amount=total_invested,
        roi=roi,
        area_name=area.get("name"),
        images=[img["image_url"] for img in area_images if img.get("image_url")],
    )


def calculate_fund_total(fund: dict) -> float:
    """Sum all cost components of a fund_details row (missing values count as 0)."""
    return sum(
        fund.get(field) or 0
        for field in ("seedling", "fertilizer", "labour", "others")
    )


# Statuses where the collected fund has already been moved to the farmer's wallet
# (see move_invested_fund). Counting them again would double count with wallet balance.
FUND_ALREADY_TRANSFERRED_STATUSES = {"Dana Sudah Ditransfer", "Selesai"}


def calculate_withdrawable_amount(investments: list[dict]) -> float:
    """Sum the collected fund of investments that reached their target amount
    and have not been transferred to the farmer's wallet yet.

    Each item needs: status, target_amount and investment_transaction (list of {amount}).
    """
    total = 0.0
    for inv in investments:
        if inv.get("status") in FUND_ALREADY_TRANSFERRED_STATUSES:
            continue

        collected = sum(t["amount"] or 0 for t in inv.get("investment_transaction") or [])
        target = inv.get("target_amount") or 0

        if target > 0 and collected >= target:
            total += collected

    return total
