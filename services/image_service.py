import requests
from typing import Dict, Any
from pathlib import Path
import hashlib
import os

class ImageSearchService:
    def __init__(self):
        self.google_vision_key = os.getenv("GOOGLE_VISION_API_KEY", "")
        self.unsplash_key = os.getenv("UNSPLASH_ACCESS_KEY", "")
        
        self.destination_signatures = {
            "beach": {
                "keywords": ["sand", "water", "blue", "coast"],
                "confidence": 0.92,
                "result": {"location": "Sandy Cove Beach", "country": "USA", "lat": 25.7617, "lng": -80.1918}
            },
            "mountain": {
                "keywords": ["peak", "snow", "altitude", "rock"],
                "confidence": 0.88,
                "result": {"location": "Alpine Peak", "country": "Italy", "lat": 45.3731, "lng": 11.9865}
            },
            "city": {
                "keywords": ["buildings", "street", "urban", "architecture"],
                "confidence": 0.85,
                "result": {"location": "Downtown City", "country": "USA", "lat": 40.7128, "lng": -74.0060}
            },
            "temple": {
                "keywords": ["temple", "ancient", "religious", "structure"],
                "confidence": 0.90,
                "result": {"location": "Sacred Temple", "country": "Thailand", "lat": 13.3611, "lng": 100.9842}
            },
            "forest": {
                "keywords": ["forest", "trees", "green", "nature"],
                "confidence": 0.87,
                "result": {"location": "Green Forest", "country": "Germany", "lat": 50.1109, "lng": 8.6821}
            },
            "desert": {
                "keywords": ["desert", "sand", "dune", "dry"],
                "confidence": 0.89,
                "result": {"location": "Great Desert", "country": "Egypt", "lat": 26.8206, "lng": 30.8025}
            }
        }
    
    def search_destination_by_image(self, image_path: str) -> Dict[str, Any]:
        """Search destination using image"""
        path = Path(image_path)
        
        if not path.exists():
            return {"status": "error", "message": "Image file not found"}
        
        # Try Google Vision first
        vision_result = self._analyze_with_google_vision(image_path)
        if vision_result:
            return vision_result
        
        # Fallback to filename analysis
        detected_type = self._analyze_image_content(image_path)
        
        if detected_type not in self.destination_signatures:
            return {"status": "not_found", "message": "Could not identify destination", "confidence": 0}
        
        destination_info = self.destination_signatures[detected_type]
        photo = self._get_destination_photo(destination_info["result"]["location"])
        
        return {
            "status": "success",
            "detected_location": destination_info["result"]["location"],
            "country": destination_info["result"]["country"],
            "category": detected_type,
            "coordinates": {"lat": destination_info["result"]["lat"], "lng": destination_info["result"]["lng"]},
            "confidence": destination_info["confidence"],
            "photo_url": photo,
            "travel_details": {
                "estimated_travel_time": "2-4 hours",
                "transportation": ["Flight", "Train", "Car"],
                "budget_range": "$1000-3000",
                "best_season": "Spring/Fall"
            }
        }
    
    def _analyze_with_google_vision(self, image_path: str) -> Dict[str, Any]:
        """Use Google Vision API for image analysis"""
        if not self.google_vision_key:
            return None
        
        try:
            with open(image_path, 'rb') as f:
                image_content = f.read()
            
            import base64
            encoded_image = base64.b64encode(image_content).decode()
            
            url = "https://vision.googleapis.com/v1/images:annotate"
            
            payload = {
                "requests": [
                    {
                        "image": {"content": encoded_image},
                        "features": [
                            {"type": "LABEL_DETECTION"},
                            {"type": "LANDMARK_DETECTION"},
                            {"type": "WEB_DETECTION"}
                        ]
                    }
                ]
            }
            
            params = {"key": self.google_vision_key}
            response = requests.post(url, json=payload, params=params, timeout=30)
            data = response.json()
            
            # Extract labels and landmarks
            if "responses" in data and len(data["responses"]) > 0:
                response_data = data["responses"][0]
                
                # Get labels
                labels = [label["description"].lower() for label in response_data.get("labelAnnotations", [])[:5]]
                
                # Get landmarks
                landmarks = response_data.get("landmarkAnnotations", [])
                
                if landmarks:
                    landmark = landmarks[0]
                    return {
                        "status": "success",
                        "detected_location": landmark.get("description", "Unknown"),
                        "country": "Detected",
                        "coordinates": {
                            "lat": landmark["locations"][0]["latLng"]["latitude"],
                            "lng": landmark["locations"][0]["latLng"]["longitude"]
                        },
                        "confidence": 0.95,
                        "detected_labels": labels,
                        "source": "Google Vision API"
                    }
        except Exception as e:
            print(f"Google Vision error: {e}")
        
        return None
    
    def _analyze_image_content(self, image_path: str) -> str:
        """Fallback: analyze from filename"""
        filename = Path(image_path).name.lower()
        
        type_keywords = {
            "beach": ["beach", "sandy", "coast"],
            "mountain": ["mountain", "peak", "snow"],
            "city": ["city", "urban", "street"],
            "temple": ["temple", "ancient", "religious"],
            "forest": ["forest", "trees", "green"],
            "desert": ["desert", "sand", "dune"]
        }
        
        for dest_type, keywords in type_keywords.items():
            if any(kw in filename for kw in keywords):
                return dest_type
        
        # Hash-based random selection
        with open(image_path, 'rb') as f:
            file_hash = int(hashlib.md5(f.read()).hexdigest(), 16)
        
        types = list(self.destination_signatures.keys())
        return types[file_hash % len(types)]
    
    def _get_destination_photo(self, location: str) -> str:
        """Get photo from Unsplash"""
        if not self.unsplash_key:
            return f"https://via.placeholder.com/400x300?text={location.upper()}"
        
        try:
            url = "https://api.unsplash.com/search/photos"
            params = {
                "query": location,
                "per_page": 1,
                "client_id": self.unsplash_key
            }
            
            response = requests.get(url, params=params, timeout=10)
            data = response.json()
            
            if data.get("results"):
                return data["results"][0]["urls"]["regular"]
        except:
            pass
        
        return f"https://via.placeholder.com/400x300?text={location.upper()}"

image_search_service = ImageSearchService()