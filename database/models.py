from sqlalchemy import Column, Integer, String, DateTime, Float, Boolean, Text
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, unique=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    language = Column(String, default="en")
    latitude = Column(Float, default=40.7128)
    longitude = Column(Float, default=-74.0060)

class Destination(Base):
    __tablename__ = "destinations"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    latitude = Column(Float)
    longitude = Column(Float)
    description = Column(Text)
    country = Column(String, index=True)
    category = Column(String)
    rating = Column(Float, default=0.0)
    photo_url = Column(String, nullable=True)

class OfflineData(Base):
    __tablename__ = "offline_data"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True)
    destination_id = Column(Integer, index=True)
    data_type = Column(String)
    cached_at = Column(DateTime, default=datetime.utcnow)
    file_path = Column(String)
    file_size = Column(Integer)
    is_synced = Column(Boolean, default=False)

class VoiceCommand(Base):
    __tablename__ = "voice_commands"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True)
    transcription = Column(Text)
    command_type = Column(String)
    results_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

class ImageSearch(Base):
    __tablename__ = "image_searches"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, index=True)
    detected_location = Column(String)
    confidence_score = Column(Float)
    created_at = Column(DateTime, default=datetime.utcnow)