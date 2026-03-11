FROM --platform=linux/amd64 ghcr.io/cirruslabs/flutter:3.38.7 AS build

WORKDIR /app

# Workaround for git dubious ownership in Docker
RUN git config --global --add safe.directory '*'

# Copy the rest of the source code
COPY . .

# Get dependencies
RUN flutter pub get -v

# Build for web
RUN flutter build web --release

# --- Production stage ---
FROM nginx:alpine

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the built web app
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
