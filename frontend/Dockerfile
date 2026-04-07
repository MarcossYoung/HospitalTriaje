FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .

# BASE_HREF controls the Flutter web base path.
# Railway (root domain): /     Local docker-compose: /triaje/
ARG BASE_HREF=/
RUN flutter build web --release --dart-define=API_BASE_URL=/api --base-href=${BASE_HREF}

FROM nginx:alpine

# DEPLOY_SUBDIR controls where built files land under /usr/share/nginx/html.
# Railway (root): empty     Local docker-compose: triaje
ARG DEPLOY_SUBDIR=
COPY --from=builder /app/build/web /tmp/webdist/
RUN mkdir -p /usr/share/nginx/html/${DEPLOY_SUBDIR} \
    && cp -a /tmp/webdist/. /usr/share/nginx/html/${DEPLOY_SUBDIR}/ \
    && rm -rf /tmp/webdist

# Use nginx template mechanism — envsubst runs automatically on *.template files at startup
COPY nginx.conf /etc/nginx/templates/default.conf.template

EXPOSE 80
