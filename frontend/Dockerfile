FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --dart-define=API_BASE_URL=/api --base-href=/triaje/

FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html/triaje
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
