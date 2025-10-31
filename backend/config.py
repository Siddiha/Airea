import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

class Config:
    # Database
    DATABASE_URL = "sqlite:///./tourism.db"
    API_TITLE = "Tourism App Backend - All Features"
    API_VERSION = "2.0.0"
    DEBUG = True
    
    # ========== FEATURE 1: VOICE ==========
    GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY", "")
    GOOGLE_CLOUD_PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT_ID", "")
    OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
    UNSPLASH_ACCESS_KEY = os.getenv("UNSPLASH_ACCESS_KEY", "")
    WEATHER_API = "open-meteo"
    
    # ========== FEATURE 2: OFFLINE ==========
    OFFLINE_CACHE_DIR = str(BASE_DIR / "data" / "offline_cache")
    MAX_CACHE_SIZE = 500 * 1024 * 1024
    
    # ========== FEATURE 3: IMAGE ==========
    GOOGLE_VISION_API_KEY = os.getenv("GOOGLE_VISION_API_KEY", "")
    AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID", "")
    AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY", "")
    AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
    UPLOADS_DIR = str(BASE_DIR / "uploads")
    IMAGE_UPLOADS_DIR = str(BASE_DIR / "uploads" / "images")

config = Config()