# syntax=docker/dockerfile:1.7
# Khmer Digital Bank API — multi-stage build.
#   docker build -t khmer-digital-bank ./backend      (or: docker compose up --build)

# ---- build ----
FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /src

# Dependencies first so they're cached until pom.xml changes.
# The cache mount keeps ~/.m2 between builds (no 5-minute re-download).
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B -q dependency:go-offline

COPY src ./src
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B -q -DskipTests package \
 && cp target/khmer-digital-bank-*.jar /app.jar

# Split the fat jar into layers (libs rarely change, app code often does).
WORKDIR /extract
RUN java -Djarmode=tools -jar /app.jar extract --layers --launcher --destination .

# ---- run ----
FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S bank && adduser -S bank -G bank
WORKDIR /app

COPY --from=build --chown=bank:bank /extract/dependencies/ ./
COPY --from=build --chown=bank:bank /extract/spring-boot-loader/ ./
COPY --from=build --chown=bank:bank /extract/snapshot-dependencies/ ./
COPY --from=build --chown=bank:bank /extract/application/ ./

USER bank
EXPOSE 8080
ENV TZ=Asia/Phnom_Penh \
    JAVA_OPTS="-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError"

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health/liveness || exit 1

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS org.springframework.boot.loader.launch.JarLauncher"]
