from fastapi import APIRouter

from app.api.health import router as health_router
from app.api.routes.auth import router as auth_router
from app.api.routes.family import router as family_router
from app.api.routes.medicine import router as medicine_router
from app.api.routes.medication import router as medication_router
from app.api.routes.medical_records import router as medical_records_router
from app.api.routes.ai import router as ai_router
from app.api.routes.notifications import router as notifications_router
from app.api.routes.pharmacy import router as pharmacy_router
from app.api.routes.upload import router as upload_router

api_router = APIRouter()
api_router.include_router(health_router)
api_router.include_router(auth_router)
api_router.include_router(family_router)
api_router.include_router(medicine_router)
api_router.include_router(medication_router)
api_router.include_router(medical_records_router)
api_router.include_router(ai_router)
api_router.include_router(notifications_router)
api_router.include_router(pharmacy_router)
api_router.include_router(upload_router)
