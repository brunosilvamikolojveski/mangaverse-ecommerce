#!/bin/sh
set -eu

if ! command -v flutter > /dev/null 2>&1; then
    if [ ! -x .flutter-sdk/bin/flutter ]; then
        git clone --depth 1 --branch 3.50.0 https://github.com/flutter/flutter.git .flutter-sdk
    fi
    export PATH="$PWD/.flutter-sdk/bin:$PATH"
fi

flutter config --no-analytics --enable-web
flutter pub get --enforce-lockfile
flutter build web --release --no-web-resources-cdn --dart-define="API_BASE_URL=${API_BASE_URL:-}"
