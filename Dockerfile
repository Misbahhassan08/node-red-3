FROM node:lts as build

RUN apt-get update \
  && apt-get install -y build-essential python perl-modules

RUN deluser --remove-home node \
  && groupadd --gid 1000 nodered \
  && useradd --gid nodered --uid 1000 --shell /bin/bash --create-home nodered

RUN mkdir -p /.node-red && chown 1000 /.node-red

USER 1000
WORKDIR /.node-red

COPY ./package.json /.node-red/
RUN npm install

## Release image
FROM node:lts-slim

RUN apt-get update && apt-get install -y perl-modules && rm -rf /var/lib/apt/lists/*

RUN deluser --remove-home node \
  && groupadd --gid 1000 nodered \
  && useradd --gid nodered --uid 1000 --shell /bin/bash --create-home nodered

RUN mkdir -p /.node-red && chown 1000 /.node-red

USER 1000

COPY ./server.js /.node-red/
COPY ./settings.js /.node-red/
COPY ./flows.json /.node-red/
COPY ./flows_cred.json /.node-red/
COPY ./package.json /.node-red/
COPY --from=build /.node-red/node_modules /.node-red/node_modules

USER 0

RUN chgrp -R 0 /.node-red \
  && chmod -R g=u /.node-red

USER 1000

WORKDIR /.node-red

RUN mkdir / .node-red/data

ENV PORT 1880
ENV NODE_ENV=production
ENV NODE_PATH=/.node-red/node_modules
EXPOSE 1880

CMD ["node", "/.node-red/server.js", "/.node-red/flows.json"]
