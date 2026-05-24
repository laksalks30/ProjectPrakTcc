# ============ FILE: frontend/Dockerfile ============
# Multi-stage build for React Frontend

# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
ARG VITE_AUTH_SERVICE_URL
ARG VITE_MEDICATION_SERVICE_URL
ENV VITE_AUTH_SERVICE_URL=$VITE_AUTH_SERVICE_URL
ENV VITE_MEDICATION_SERVICE_URL=$VITE_MEDICATION_SERVICE_URL
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:alpine AS production
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
