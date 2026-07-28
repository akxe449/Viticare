# ---------- Stage 1: build the Next.js frontend ----------
FROM node:20-slim AS frontend-build
WORKDIR /app/Frontend
COPY Frontend/package.json Frontend/package-lock.json ./
RUN npm ci
COPY Frontend/ ./
RUN npm run build

# ---------- Stage 2: final runtime image ----------
FROM python:3.11-slim

# Node.js is needed at runtime to run `next start`
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# --- Backend ---
COPY Backend/requirements.txt Backend/requirements.txt
RUN pip3 install --no-cache-dir -r Backend/requirements.txt
COPY Backend/ Backend/

# --- Data (may be empty if you haven't added real data yet) ---
COPY Data/ Data/
RUN mkdir -p Data/segmented Data/raw Data/registered

# --- Frontend (built artifacts + what's needed to run `next start`) ---
COPY --from=frontend-build /app/Frontend/.next Frontend/.next
COPY --from=frontend-build /app/Frontend/public Frontend/public
COPY --from=frontend-build /app/Frontend/node_modules Frontend/node_modules
COPY --from=frontend-build /app/Frontend/package.json Frontend/package.json
COPY --from=frontend-build /app/Frontend/next.config.ts Frontend/next.config.ts

COPY start.sh start.sh
RUN chmod +x start.sh

# Hugging Face Spaces (Docker SDK) expects the app on port 7860
EXPOSE 7860
ENV PORT=7860
ENV NEXT_PUBLIC_API_BASE=/api

CMD ["./start.sh"]
