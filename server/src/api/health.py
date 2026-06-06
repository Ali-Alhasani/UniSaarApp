from fastapi import APIRouter
from pydantic import BaseModel

from src.core.routes import Route

router = APIRouter()


class HealthResponse(BaseModel):
    status: str


@router.get(Route.HEALTH, response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse(status="ok")
