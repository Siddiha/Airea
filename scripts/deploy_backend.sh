#!/bin/bash
# Backend deployment script

cd backend-springboot
mvn clean package
java -jar target/airea-backend-1.0.0.jar

