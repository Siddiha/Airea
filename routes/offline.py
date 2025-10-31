from fastapi import APIRouter, HTTPException, Query
from typing import Dict, Any
from ..services.offline_service import offline_manager

router = APIRouter(prefix="/api/offline", tags=["💾 Offline Mode"])

@router.get("/status")
async def get_offline_status(user_id: str = Query(...)) -> Dict[str, Any]:
    """Get offline cache status"""
    try:
        return offline_manager.get_cache_status(user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/download")
async def download_for_offline(
    user_id: str = Query(...),
    destination_id: int = Query(...),
    data_type: str = Query("map", regex="^(map|guide|itinerary|hotels)$")
) -> Dict[str, Any]:
    """
    Download destination data for offline use
    
    data_type: map, guide, itinerary, hotels
    """
    try:
        return offline_manager.download_for_offline(user_id, destination_id, data_type)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/sync")
async def sync_offline_data(user_id: str = Query(...)) -> Dict[str, Any]:
    """Sync offline changes"""
    try:
        return offline_manager.sync_offline_data(user_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/storage-info")
async def get_storage_info(user_id: str = Query(...)) -> Dict[str, Any]:
    """Get storage information"""
    return offline_manager.get_storage_info(user_id)