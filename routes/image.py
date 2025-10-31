from fastapi import APIRouter, File, UploadFile, HTTPException, Query
from typing import Dict, Any
from pathlib import Path
import aiofiles
from ..services.image_service import image_search_service

router = APIRouter(prefix="/api/image", tags=["🖼️ Image Search"])

UPLOAD_DIR = Path("./uploads/images")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

@router.post("/search")
async def search_destination_by_image(
    user_id: str = Query(...),
    image_file: UploadFile = File(...)
) -> Dict[str, Any]:
    """
    Upload image to search for destination
    
    Supports: jpg, jpeg, png, webp
    """
    if not image_file.filename.endswith(('.jpg', '.jpeg', '.png', '.webp')):
        raise HTTPException(status_code=400, detail="Unsupported image format")
    
    filepath = UPLOAD_DIR / f"{user_id}_{image_file.filename}"
    
    try:
        contents = await image_file.read()
        async with aiofiles.open(filepath, 'wb') as f:
            await f.write(contents)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save image: {str(e)}")
    
    try:
        result = image_search_service.search_destination_by_image(str(filepath))
        return {
            "user_id": user_id,
            "filename": image_file.filename,
            **result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/popular-destinations")
async def get_popular_destinations() -> Dict[str, Any]:
    """Get list of recognizable destinations"""
    return {
        "destinations": [
            {"name": "Sandy Cove Beach", "category": "beach", "country": "USA"},
            {"name": "Alpine Peak", "category": "mountain", "country": "Italy"},
            {"name": "Downtown City", "category": "city", "country": "USA"},
            {"name": "Sacred Temple", "category": "temple", "country": "Thailand"},
            {"name": "Green Forest", "category": "forest", "country": "Germany"},
            {"name": "Great Desert", "category": "desert", "country": "Egypt"}
        ]
    }