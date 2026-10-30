# ---------- Etapa 1: build ----------
FROM eclipse-temurin:24-jdk-alpine AS build
WORKDIR /workspace

# Se copian primero pom y wrapper para aprovechar la cache de capas de Docker
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw && ./mvnw -B -q dependency:go-offline

COPY src/ src/
RUN ./mvnw -B -q -DskipTests package && \
    cp target/cl-matiivilla-vehiculos-*.jar app.jar

# ---------- Etapa 2: runtime (imagen minima, usuario no root) ----------
FROM eclipse-temurin:24-jre-alpine
WORKDIR /app

RUN addgroup -S app && adduser -S app -G app
COPY --from=build /workspace/app.jar app.jar
USER app

ENV JAVA_OPTS="-XX:MaxRAMPercentage=75" \
    SERVER_PORT=9004
EXPOSE 9004

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
