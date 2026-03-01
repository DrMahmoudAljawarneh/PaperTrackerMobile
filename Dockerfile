FROM --platform=linux/amd64 ghcr.io/cirruslabs/flutter:3.29.2 AS build

WORKDIR /app

# Copy dependency files first for caching
COPY pubspec.yaml pubspec.lock* ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the source code
COPY . .

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
