from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from user.route import router as user_router
from area.route import router as area_router
from investment.route import router as investment_router
from payments.route import router as payment_router
from report.route import router as report_router
from update.route import router as update_router


app = FastAPI()

# ── CORS ─────────────────────────────────────────────────────────────────────
# allow_origins=["*"] untuk development.
# Ganti dengan domain spesifik saat production, contoh:
# ["https://app.tfund.id", "https://admin.tfund.id"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,  # NOTE: tidak bisa True jika allow_origins=["*"]
    # Saat production, ganti ke domain spesifik dan set credentials=True:
    # allow_origins=["https://app.tfund.id", "https://admin.tfund.id"],
    # allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(user_router)
app.include_router(area_router)
app.include_router(investment_router)
app.include_router(payment_router)
app.include_router(report_router)
app.include_router(update_router)


@app.get("/")
async def root():
    return {"message": "Hello Bigger Applications!"}
