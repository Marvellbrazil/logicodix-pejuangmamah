FROM node:24-slim

WORKDIR /app
ENV NODE_ENV=production

COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts

COPY src ./src

# SQLite disimpan di volume permanen yang di-mount ke /data.
ENV HOST=0.0.0.0
ENV DATABASE_PATH=/data/kerjaqueue.db

EXPOSE 8080
CMD ["node", "src/index.ts"]
