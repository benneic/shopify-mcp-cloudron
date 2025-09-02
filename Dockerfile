FROM node:20-alpine

RUN apk add --no-cache curl

WORKDIR /app

COPY server.js /app/

EXPOSE 8080

ENV PORT=8080
ENV AUTH_TYPE=""
ENV AUTH_TOKEN=""
ENV AUTH_HEADER_NAME="Authorization"
ENV OPT_OUT_INSTRUMENTATION="false"
ENV POLARIS_UNIFIED="false"
ENV LIQUID="false"
ENV LIQUID_VALIDATION_MODE="partial"

RUN addgroup -g 1000 cloudron 2>/dev/null || true && \
    adduser -u 1000 -G cloudron -s /bin/sh -D cloudron 2>/dev/null || \
    (deluser node 2>/dev/null || true && delgroup node 2>/dev/null || true && \
     addgroup -g 1000 cloudron && adduser -u 1000 -G cloudron -s /bin/sh -D cloudron) && \
    chown -R cloudron:cloudron /home/cloudron

USER cloudron

ENV NPM_CONFIG_CACHE=/tmp/.npm

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:$PORT/health || exit 1

CMD ["node", "/app/server.js"]