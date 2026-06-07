# syntax=docker/dockerfile:1

# ---- Stage 1: Build ----
# Full JDK only needed to compile and package the app.
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /workspace

# Copy build scripts first so dependency resolution is cached
# independently of source-code changes.
COPY gradlew settings.gradle build.gradle ./
COPY gradle ./gradle
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon || true

# Now copy the source and build the executable jar.
COPY src ./src
RUN ./gradlew clean bootJar --no-daemon && cp build/libs/*-SNAPSHOT.jar application.jar

# Explode the jar into Spring Boot layers for better image-layer caching.
RUN java -Djarmode=tools -jar application.jar extract --layers --destination extracted

# ---- Stage 2: Runtime ----
# Minimal JRE base image — no compiler, smaller attack surface.
FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /application

# Run as an unprivileged user instead of root.
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy layers most-stable-first so Docker reuses cached layers across builds.
COPY --from=build /workspace/extracted/dependencies/ ./
COPY --from=build /workspace/extracted/spring-boot-loader/ ./
COPY --from=build /workspace/extracted/snapshot-dependencies/ ./
COPY --from=build /workspace/extracted/application/ ./

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "application.jar"]
