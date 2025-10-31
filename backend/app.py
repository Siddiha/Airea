from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .config import config
from .routes import voice, offline, image
from .database import init_db

# Initialize database
init_db()

app = FastAPI(
    title=config.API_TITLE,
    version=config.API_VERSION,
    description="🚀 Tourism App Backend - All 3 Features with Real APIs"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(voice.router)
app.include_router(offline.router)
app.include_router(image.router)

@app.get("/")
async def root():
    return {
        "message": "🎉 Welcome to Tourism App Backend",
        "version": config.API_VERSION,
        "features": [
            "🎤 Voice Navigation - Find places by voice commands",
            "💾 Offline Mode - Download data for offline use",
            "🖼️ Image Search - Find destinations from photos"
        ],
        "docs": "Visit http://localhost:8000/docs"
    }

@app.get("/health")
async def health_check():
    return {"status": "✅ Healthy", "service": "Tourism App Backend"}

@app.get("/features")
async def list_features():
    return {
        "features": {
            "voice_navigation": {
                "endpoint": "/api/voice/process",
                "description": "Find places by voice commands with weather",
                "example": "Find coffee shops"
            },
            "offline_mode": {
                "endpoint": "/api/offline/download",
                "description": "Download & sync offline data",
                "supported_types": ["map", "guide", "itinerary", "hotels"]
            },
            "image_search": {
                "endpoint": "/api/image/search",
                "description": "Upload image to find destination"
            }
        }
    }