FROM debian:bookworm-slim AS build

ARG FLUTTER_VERSION=3.44.8
ARG FLUTTER_SHA256=672089e001571a9fbb209a495c583580c0c6c73ef98999264ba07fa93ace332d

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
        -o /tmp/flutter.tar.xz \
    && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c - \
    && tar -xf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    && git config --global --add safe.directory /opt/flutter

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter config --enable-web \
    && flutter precache --web

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY assets ./assets
COPY lib ./lib
COPY web ./web

ARG API_BASE_URL=http://localhost:8081
ARG KEYCLOAK_ISSUER=http://localhost:8000/realms/polarforecast-web
ARG REDIRECT_URI=http://localhost:3000/
ARG POST_LOGOUT_REDIRECT_URI=http://localhost:3000/

RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=KEYCLOAK_ISSUER=${KEYCLOAK_ISSUER} \
    --dart-define=REDIRECT_URI=${REDIRECT_URI} \
    --dart-define=POST_LOGOUT_REDIRECT_URI=${POST_LOGOUT_REDIRECT_URI}

FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
