from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from data.loader import load_all_data, load_stadium_map, load_model_bundle
from api.v1.router import v1_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.df = load_all_data(settings.resolved_data_path)
    app.state.stadium_map = load_stadium_map(settings.resolved_stadium_map_path)
    app.state.bundle = load_model_bundle(settings.resolved_model_path)
    yield


app = FastAPI(
    title="UmbraRo API",
    description="Tactical intelligence backend for UmbraRo",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(v1_router, prefix="/api/v1")
