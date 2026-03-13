FROM eclipse-temurin:17-jdk AS build

WORKDIR /app

COPY gradle/ gradle/
COPY gradlew .
COPY build.gradle.kts .
COPY settings.gradle.kts .
COPY gradle.properties .
COPY app/ app/

RUN chmod +x gradlew
RUN ./gradlew assembleRelease --no-daemon

FROM scratch AS export
COPY --from=build /app/app/build/outputs/apk/release/ /apk/
