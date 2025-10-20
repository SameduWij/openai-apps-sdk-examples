# Dockerfile for Node.js backend
FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
CMD ["npx", "tsx", "src/server.ts"]