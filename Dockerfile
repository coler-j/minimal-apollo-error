#######################################################################################
#   _______             .___       ________                 __                        #
#    \      \   ____   __| _/____   \______ \   ____   ____ |  | __ ___________       #
#    /   |   \ /  _ \ / __ |/ __ \   |    |  \ /  _ \_/ ___\|  |/ // __ \_  __ \      #
#   /    |    (  <_> ) /_/ \  ___/   |    `   (  <_> )  \___|    <\  ___/|  | \/      #
#   \____|__  /\____/\____ |\___  > /_______  /\____/ \___  >__|_ \\___  >__|         #
#          \/            \/    \/          \/            \/     \/    \/              #
#                                                                                     #
#     A multi-stage Dockerfile for building and running NestJS applications which     #
#      uses Yarn 3 and PnP and supports development and production environments.      #
#######################################################################################


# ------------------ Base Image ------------------ #

FROM --platform=$BUILDPLATFORM public.ecr.aws/docker/library/node:18.13.0-bullseye-slim as base

# See https://github.com/nestjs/nest-cli/issues/484#issuecomment-683967257
RUN apt-get update && apt-get install -y procps

# See https://github.com/nodejs/docker-node/blob/master/docs/BestPractices.md#handling-kernel-signals
RUN apt-get update && apt-get install -y --no-install-recommends dumb-init

RUN yarn set version berry
RUN yarn set version 3.3.1

USER node

WORKDIR /app

COPY --chown=node:node .yarnrc.yml      .yarnrc.yml
COPY --chown=node:node .yarn/cache/     .yarn/cache/
COPY --chown=node:node .yarn/plugins/   .yarn/plugins/
COPY --chown=node:node .yarn/releases/  .yarn/releases/
COPY --chown=node:node package.json     package.json
COPY --chown=node:node yarn.lock        yarn.lock


# ------------------ Dependencies Stage ----------------- #

FROM base as build-dependencies

RUN yarn install --immutable --immutable-cache

FROM base as prod-dependencies

ENV NODE_ENV=production

# `yarn workspaces focus --all --production` is equivalent to `yarn install --production`
# See https://yarnpkg.com/getting-started/migration#renamed
RUN yarn workspaces focus --all --production


# -------------------- Source Stage --------------------- #

FROM build-dependencies as source

COPY --chown=node:node src                  ./src
COPY --chown=node:node test                 ./test
COPY --chown=node:node tsconfig.json        tsconfig.json
COPY --chown=node:node tsconfig.build.json  tsconfig.build.json


# ------------------ Development Image ------------------ #

FROM source as development

ENV NODE_ENV=development

# Run Dev by providing run command in infra/values_dev.yaml as well as
# docker stage target as `docker build . --target development`


# --------------- Production Build Stage ---------------- #


FROM source as prod-build

ENV NODE_ENV=production

RUN yarn build


# ----------------- Production Image ------------------- #

FROM base as prod

ENV NODE_ENV=production

COPY --from=prod-dependencies /app/.yarn/unplugged        .yarn/unplugged
COPY --from=prod-dependencies /app/.pnp.cjs        .pnp.cjs
COPY --from=prod-dependencies /app/.pnp.loader.mjs .pnp.loader.mjs
COPY --from=prod-build        /app/dist            dist

ARG APPLICATION_PORT=3000
EXPOSE $APPLICATION_PORT

CMD ["dumb-init", "node", "-r", "./.pnp.cjs", "dist/main", $APPLICATION_PORT]
