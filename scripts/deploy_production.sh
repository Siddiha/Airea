#!/bin/bash
# Production deployment script

echo "Deploying Airea to production..."

# Build backend
cd backend-springboot
./mvnw clean package
cd ..

# Build Flutter
cd frontend-flutter
flutter build apk --release
flutter build ios --release
cd ..

echo "✅ Deployment packages ready!"

