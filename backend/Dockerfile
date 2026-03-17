# Build stage
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY . .
RUN if [ -f backend/pom.xml ]; then \
    mvn -f backend/pom.xml clean package -DskipTests && \
    cp backend/target/*.jar /app/app.jar; \
    else \
    mvn -f pom.xml clean package -DskipTests && \
    cp target/*.jar /app/app.jar; \
    fi

# Run stage
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/app.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
