#!/bin/bash
# Start all services locally

# Start PostgreSQL (if using Docker)
docker-compose up -d postgres

# Start Backend
cd backend-springboot
./mvnw spring-boot:run &
cd ..

# Start Frontend (in separate terminal)
echo "Start Flutter app with: cd frontend-flutter && flutter run"

