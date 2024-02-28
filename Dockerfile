FROM node:18-alpine as base

WORKDIR /app

# Dir ENVs need to be set before building or else build throws errors
ENV PUBLIC_KENER_FOLDER=./static/kener \
    MONITOR_YAML_PATH=./config/monitors.yaml \
    SITE_YAML_PATH=./config/site.yaml

# build requires devDependencies which are not used by production deploy
# so build in a stage so we can copy results to clean "deploy" stage later
FROM base as build

COPY . /app

RUN npm install
RUN npm run kener:build

FROM base as app

COPY  package*.json ./
COPY  scripts /app/scripts
COPY  static /app/static
COPY  config /app/config
# Needed cause build is not complete
COPY  src /app/src
COPY --from=build /app/build /app/build
COPY --from=build /app/prod.js /app/prod.js

ENV NODE_ENV=production

# install prod depdendencies and clean cache
RUN npm install --omit=dev \
    && npm cache clean --force
  
# Non-root user for better security
RUN addgroup nodejs && adduser -S -G nodejs kener
RUN chown -R kener:nodejs .
USER kener

ENV PORT=3000
EXPOSE $PORT

CMD ["node", "prod.js"]
