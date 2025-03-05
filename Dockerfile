# Use an official Flutter image with web support
FROM cirrusci/flutter:latest AS build

# Set working directory inside the container
WORKDIR /app

# Copy the Flutter project files
COPY . .

# Enable Flutter web
RUN flutter config --enable-web

# Get dependencies
RUN flutter pub get

# Build the Flutter web app
RUN flutter build web

# Use Nginx to serve the built files
FROM nginx
COPY --from=build /app/build/web /usr/share/nginx/html
