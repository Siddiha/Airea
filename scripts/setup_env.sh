#!/bin/bash
# Setup environment script

echo "Setting up Airea project environment..."

# Create virtual environment for ML training
cd ml-training
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Setup backend
cd ../backend-springboot
mvn clean install

# Setup frontend
cd ../frontend-flutter
flutter pub get

echo "✅ Environment setup complete!"

