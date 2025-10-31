import requests
import os
from typing import Dict, Any
from math import radians, cos, sin, asin, sqrt

class VoiceProcessor:
    def __init__(self):
        self.google_maps_key = os.getenv("GOOGLE_MAPS_API_KEY", "")
        self.unsplash_key = os.getenv("UNSPLASH_ACCESS_KEY", "")
        
        self.search_types = {
            "coffee": {"query": "coffee shop", "type": "cafe"},
            "restaurant": {"query": "restaurant", "type": "restaurant"},
            "hotel": {"query": "hotel", "type": "lodging"},
            "beach": {"query": "beach", "type": "natural_feature"},
            "mountain": {"query": "mountain", "type": "natural_feature"},
            "museum": {"query": "museum", "type": "museum"},
            "park": {"query": "park", "type": "park"},
            "hospital": {"query": "hospital", "type": "hospital"},
            "pharmacy": {"query": "pharmacy", "type": "pharmacy"},
            "atm": {"query": "atm", "type": "atm"},
        }
        
        self.keywords = {
            "coffee": ["coffee", "cafe", "espresso", "latte", "cappuccino"],
            "restaurant": ["restaurant", "food", "eat", "dining", "lunch", "dinner"],
            "hotel": ["hotel", "accommodation", "stay", "lodge", "room"],
            "beach": ["beach", "sandy", "coast", "seaside", "ocean"],
            "mountain": ["mountain", "hiking", "peak", "trail", "climbing"],
            "museum": ["museum", "gallery", "art", "history", "exhibit"],
            "park": ["park", "garden", "nature", "outdoor", "green"],
            "hospital": ["hospital", "doctor", "medical", "emergency", "clinic"],
            "pharmacy": ["pharmacy", "medicine", "drug", "prescription"],
            "atm": ["atm", "cash", "bank", "money"],
        }
    
    def process_command(self, transcription: str, latitude: float = 40.7128, 
                       longitude: float = -74.0060) -> Dict[str, Any]:
        """Process voice command and search real locations"""
        text_lower = transcription.lower().strip()
        detected_intent = self._detect_intent(text_lower)
        
        if not detected_intent:
            return {
                "status": "failed",
                "message": "Could not understand. Try: 'Find coffee' or 'Show restaurants'",
                "intent": None,
                "destinations": []
            }
        
        search_results = self._search_places(detected_intent, latitude, longitude)
        
        if not search_results:
            return {
                "status": "no_results",
                "message": f"No {detected_intent}s found nearby",
                "intent": detected_intent,
                "destinations": []
            }
        
        destinations_with_weather = []
        for place in search_results[:5]:
            weather = self._get_weather(place["lat"], place["lng"])
            photo = self._get_place_photo(detected_intent)
            
            destinations_with_weather.append({
                "name": place["name"],
                "latitude": place["lat"],
                "longitude": place["lng"],
                "address": place["address"],
                "distance_km": place["distance"],
                "rating": place.get("rating", "N/A"),
                "weather": weather,
                "photo_url": photo,
            })
        
        return {
            "status": "success",
            "message": f"Found {len(destinations_with_weather)} {detected_intent}s",
            "intent": detected_intent,
            "destinations": destinations_with_weather,
        }
    
    def _detect_intent(self, text: str) -> str:
        for intent, keywords in self.keywords.items():
            for keyword in keywords:
                if keyword in text:
                    return intent
        return None
    
    def _search_places(self, search_type: str, latitude: float, longitude: float, radius: int = 5000) -> list:
        """Search using Google Places API"""
        if not self.google_maps_key:
            return self._get_demo_places(search_type)
        
        try:
            url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
            search_info = self.search_types.get(search_type, {})
            
            params = {
                "location": f"{latitude},{longitude}",
                "radius": radius,
                "type": search_info.get("type", "point_of_interest"),
                "keyword": search_info.get("query", search_type),
                "key": self.google_maps_key
            }
            
            response = requests.get(url, params=params, timeout=10)
            data = response.json()
            
            if data["status"] != "OK":
                return self._get_demo_places(search_type)
            
            results = []
            for place in data.get("results", [])[:5]:
                location = place["geometry"]["location"]
                results.append({
                    "name": place["name"],
                    "lat": location["lat"],
                    "lng": location["lng"],
                    "address": place.get("vicinity", "N/A"),
                    "rating": place.get("rating", 0),
                    "distance": self._calculate_distance(latitude, longitude, location["lat"], location["lng"])
                })
            
            return results
        except Exception as e:
            print(f"Error: {e}")
            return self._get_demo_places(search_type)
    
    def _get_demo_places(self, search_type: str) -> list:
        """Demo data if API not available"""
        demos = {
            "coffee": [{"name": "Brew Haven", "lat": 40.7138, "lng": -74.0059, "address": "123 Main St", "distance": 0.5, "rating": 4.7}],
            "restaurant": [{"name": "Italian Kitchen", "lat": 40.7148, "lng": -74.0069, "address": "456 Park Ave", "distance": 0.8, "rating": 4.8}],
            "hotel": [{"name": "Grand Hotel", "lat": 40.7158, "lng": -74.0079, "address": "789 Star Ave", "distance": 1.2, "rating": 4.9}],
            "beach": [{"name": "Sandy Cove", "lat": 40.7268, "lng": -74.0179, "address": "Beach Rd", "distance": 5.0, "rating": 4.8}],
        }
        return demos.get(search_type, [])
    
    def _get_weather(self, latitude: float, longitude: float) -> Dict[str, Any]:
        """Get weather from Open-Meteo (100% FREE)"""
        try:
            url = "https://api.open-meteo.com/v1/forecast"
            params = {
                "latitude": latitude,
                "longitude": longitude,
                "current": "temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m",
                "timezone": "auto"
            }
            
            response = requests.get(url, params=params, timeout=10)
            data = response.json()
            current = data.get("current", {})
            
            return {
                "temperature_c": current.get("temperature_2m", "N/A"),
                "wind_speed": current.get("wind_speed_10m", "N/A"),
                "humidity": current.get("relative_humidity_2m", "N/A"),
                "timezone": data.get("timezone", "UTC")
            }
        except Exception as e:
            return {"status": "unavailable", "error": str(e)}
    
    def _get_place_photo(self, search_type: str) -> str:
        """Get photo from Unsplash (100% FREE)"""
        if not self.unsplash_key:
            return f"https://via.placeholder.com/400x300?text={search_type.upper()}"
        
        try:
            url = "https://api.unsplash.com/search/photos"
            params = {
                "query": search_type,
                "per_page": 1,
                "client_id": self.unsplash_key
            }
            
            response = requests.get(url, params=params, timeout=10)
            data = response.json()
            
            if data.get("results"):
                return data["results"][0]["urls"]["regular"]
        except:
            pass
        
        return f"https://via.placeholder.com/400x300?text={search_type.upper()}"
    
    def _calculate_distance(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance in km"""
        lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
        dlon = lon2 - lon1
        dlat = lat2 - lat1
        a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
        c = 2 * asin(sqrt(a))
        r = 6371
        return round(c * r, 2)

voice_processor = VoiceProcessor()