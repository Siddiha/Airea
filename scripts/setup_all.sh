#!/bin/bash
# Setup all environments

echo "Setting up Airea project..."

# ML Training
cd ml-training
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cd ..

# Backend
cd backend-springboot
./mvnw install
cd ..

# Frontend
cd frontend-flutter
flutter pub get
cd ..

echo "✅ Setup complete!"

