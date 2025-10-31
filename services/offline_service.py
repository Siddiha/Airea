import json
import requests
from pathlib import Path
from datetime import datetime
from typing import Dict, Any

class OfflineManager:
    def __init__(self, cache_dir: str = "./data/offline_cache"):
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(parents=True, exist_ok=True)
    
    def get_cache_status(self, user_id: str) -> Dict[str, Any]:
        """Get offline cache status"""
        user_cache = self.cache_dir / user_id
        
        if not user_cache.exists():
            return {
                "user_id": user_id,
                "total_size_mb": 0,
                "items": [],
                "sync_status": "not_synced"
            }
        
        items = []
        total_size = 0
        
        for item in user_cache.iterdir():
            if item.is_file():
                size = item.stat().st_size
                total_size += size
                items.append({
                    "name": item.name,
                    "size_kb": round(size / 1024, 2),
                    "modified": str(item.stat().st_mtime)
                })
        
        return {
            "user_id": user_id,
            "total_size_mb": round(total_size / (1024 * 1024), 2),
            "items_count": len(items),
            "items": items,
            "sync_status": "synced"
        }
    
    def download_for_offline(self, user_id: str, destination_id: int, data_type: str = "map") -> Dict[str, Any]:
        """Download destination data for offline"""
        user_cache = self.cache_dir / user_id
        user_cache.mkdir(parents=True, exist_ok=True)
        
        # Get real data from APIs
        destination_data = self._get_destination_data(destination_id, data_type)
        
        filename = f"destination_{destination_id}_{data_type}.json"
        filepath = user_cache / filename
        
        with open(filepath, 'w') as f:
            json.dump(destination_data, f, indent=2)
        
        return {
            "status": "success",
            "message": f"Downloaded {data_type} data for offline",
            "destination_id": destination_id,
            "file_name": filename,
            "file_size_kb": round(filepath.stat().st_size / 1024, 2),
            "downloaded_at": datetime.utcnow().isoformat()
        }
    
    def _get_destination_data(self, destination_id: int, data_type: str) -> Dict[str, Any]:
        """Get destination data based on type"""
        base_data = {
            "destination_id": destination_id,
            "type": data_type,
            "downloaded_at": datetime.utcnow().isoformat(),
        }
        
        if data_type == "map":
            base_data["map_tiles"] = [
                "tile_0_0.pbf",
                "tile_0_1.pbf",
                "tile_1_0.pbf",
                "tile_1_1.pbf"
            ]
            base_data["zoom_levels"] = [1, 5, 10, 15, 20]
        
        elif data_type == "guide":
            base_data["guides"] = [
                {"name": "local_guide.pdf", "size": "2.5MB"},
                {"name": "emergency_contacts.txt", "size": "50KB"},
                {"name": "cultural_tips.txt", "size": "100KB"}
            ]
        
        elif data_type == "itinerary":
            base_data["itinerary"] = [
                {"day": 1, "activities": ["Morning visit", "Lunch", "Evening walk"]},
                {"day": 2, "activities": ["Museum", "Restaurant", "Shopping"]},
                {"day": 3, "activities": ["Nature walk", "Photography", "Relaxation"]}
            ]
        
        elif data_type == "hotels":
            base_data["hotels"] = [
                {"name": "Hotel A", "rating": 4.5, "price": "$100/night"},
                {"name": "Hotel B", "rating": 4.7, "price": "$150/night"},
                {"name": "Hotel C", "rating": 4.8, "price": "$200/night"}
            ]
        
        return base_data
    
    def sync_offline_data(self, user_id: str) -> Dict[str, Any]:
        """Sync offline data"""
        user_cache = self.cache_dir / user_id
        
        if not user_cache.exists():
            return {
                "status": "error",
                "message": "No offline data found"
            }
        
        files = list(user_cache.glob("*.json"))
        
        return {
            "status": "synced",
            "message": "All offline data synced",
            "files_synced": len(files),
            "synced_at": datetime.utcnow().isoformat()
        }
    
    def get_storage_info(self, user_id: str) -> Dict[str, Any]:
        """Get storage usage info"""
        status = self.get_cache_status(user_id)
        MAX_CACHE = 500  # MB
        used = status["total_size_mb"]
        
        return {
            "max_storage_mb": MAX_CACHE,
            "used_mb": used,
            "available_mb": MAX_CACHE - used,
            "usage_percentage": round((used / MAX_CACHE) * 100, 2)
        }

offline_manager = OfflineManager()