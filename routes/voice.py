from fastapi import APIRouter, File, UploadFile, HTTPException, Query
from typing import Dict, Any
from ..services.voice_service import voice_processor

router = APIRouter(prefix="/api/voice", tags=["🎤 Voice Navigation"])

@router.post("/process")
async def process_voice_command(
    user_id: str = Query(..., description="User ID"),
    text_input: str = Query(..., description="Voice command text"),
    latitude: float = Query(40.7128, description="User latitude"),
    longitude: float = Query(-74.0060, description="User longitude")
) -> Dict[str, Any]:
    """
    Process voice command text and find nearby locations
    
    Example: "Find coffee shops" → Returns 5 nearby coffee shops with weather
    """
    try:
        result = voice_processor.process_command(text_input, latitude, longitude)
        return {
            "user_id": user_id,
            "command": text_input,
            "user_location": {"latitude": latitude, "longitude": longitude},
            **result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/transcribe-audio")
async def transcribe_audio(
    user_id: str = Query(...),
    audio_file: UploadFile = File(...),
    latitude: float = Query(40.7128),
    longitude: float = Query(-74.0060)
) -> Dict[str, Any]:
    """Transcribe audio file and process as voice command"""
    if not audio_file.filename.endswith(('.wav', '.mp3', '.m4a', '.ogg')):
        raise HTTPException(status_code=400, detail="Unsupported audio format")
    
    # Mock transcription (use OpenAI Whisper in production)
    simulated_transcription = "Find restaurants nearby"
    result = voice_processor.process_command(simulated_transcription, latitude, longitude)
    
    return {
        "user_id": user_id,
        "filename": audio_file.filename,
        "transcription": simulated_transcription,
        **result
    }

@router.get("/nearby-search")
async def nearby_search(
    search_type: str = Query(..., description="coffee, restaurant, hotel, beach, mountain, museum, park"),
    latitude: float = Query(40.7128),
    longitude: float = Query(-74.0060),
    radius: int = Query(5000, description="Search radius in meters")
) -> Dict[str, Any]:
    """Search for nearby places"""
    results = voice_processor._search_places(search_type, latitude, longitude, radius)
    
    if not results:
        return {"status": "no_results", "message": f"No {search_type}s found"}
    
    destinations = []
    for place in results:
        weather = voice_processor._get_weather(place["lat"], place["lng"])
        destinations.append({**place, "weather": weather})
    
    return {
        "status": "success",
        "search_type": search_type,
        "total_results": len(destinations),
        "destinations": destinations
    }

@router.get("/weather")
async def get_weather(
    latitude: float = Query(40.7128),
    longitude: float = Query(-74.0060)
) -> Dict[str, Any]:
    """Get weather for location"""
    weather = voice_processor._get_weather(latitude, longitude)
    return {
        "location": {"latitude": latitude, "longitude": longitude},
        "weather": weather
    }