# Dockerfile for frontend (Vite React)
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install --frozen-lockfile
COPY . .
RUN pnpm run build

FROM nginx:alpine
# Copy built assets to Nginx web root
COPY --from=build /app/assets /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]