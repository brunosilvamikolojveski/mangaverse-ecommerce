FROM debian:bookworm-slim AS flutter
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch 3.50.0 https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:$PATH"
RUN flutter config --no-analytics --enable-web

FROM flutter AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get --enforce-lockfile
COPY . .
ARG API_BASE_URL=""
RUN flutter build web --release --no-web-resources-cdn --dart-define="API_BASE_URL=$API_BASE_URL"

FROM nginx:1.28-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
