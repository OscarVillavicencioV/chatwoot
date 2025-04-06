# Etapa 1: Node base (para JS deps)
FROM node:23-alpine as node

# Etapa 2: Pre-build con Ruby y Node
FROM ruby:3.3.3-alpine3.19 as pre-builder

ENV BUNDLER_VERSION=2.5.6
ENV RAILS_ENV=production \
    NODE_ENV=production \
    INSTALLATION_ENV=docker \
    LANG=C.UTF-8 \
    RAILS_LOG_TO_STDOUT=true

RUN apk update && apk add --no-cache \
  openssl \
  tar \
  build-base \
  tzdata \
  postgresql-dev \
  postgresql-client \
  git \
  curl \
  xz \
  vips \
  g++ \
  libffi-dev \
  linux-headers \
  && mkdir -p /app \
  && gem install bundler -v "$BUNDLER_VERSION"

WORKDIR /app

# Copia Node desde la etapa previa
COPY --from=node /usr/local/bin/node /usr/local/bin/
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules

# Vincula npm/npx
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
  && ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
  && npm install -g pnpm@10.2.0

# Bundle install
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local force_ruby_platform true
RUN bundle config set without 'development test'
RUN bundle install -j4

# Instalar dependencias JS
COPY package.json pnpm-lock.yaml ./
RUN pnpm install

# Copiar el resto del código
COPY . .

# Preparar assets
RUN mkdir -p /app/log
RUN SECRET_KEY_BASE=precompile_placeholder bundle exec rake assets:precompile

# Etapa final
FROM ruby:3.3.3-alpine3.19 as final

ENV BUNDLER_VERSION=2.5.6
ENV RAILS_ENV=production \
    NODE_ENV=production \
    INSTALLATION_ENV=docker \
    LANG=C.UTF-8 \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true

RUN apk update && apk add --no-cache \
  build-base \
  openssl \
  tzdata \
  postgresql-client \
  imagemagick \
  git \
  vips \
  && gem install bundler -v "$BUNDLER_VERSION"

WORKDIR /app

# Copia todo desde la preconstrucción
COPY --from=pre-builder /app /app
COPY --from=pre-builder /usr/local/lib/ruby /usr/local/lib/ruby
COPY --from=pre-builder /usr/local/bundle /usr/local/bundle

EXPOSE 3000

CMD ["bash", "-c", "bundle exec rails db:prepare && bundle exec puma -C config/puma.rb"]

