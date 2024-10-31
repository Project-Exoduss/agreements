FROM ruby:3.3.4-alpine as fonts

WORKDIR /fonts

RUN apk --no-cache add fontforge wget && \
    wget https://github.com/satbyy/go-noto-universal/releases/download/v7.0/GoNotoKurrent-Regular.ttf && \
    wget https://github.com/satbyy/go-noto-universal/releases/download/v7.0/GoNotoKurrent-Bold.ttf && \
    wget https://github.com/impallari/DancingScript/raw/master/fonts/DancingScript-Regular.otf && \
    wget https://github.com/notofonts/notofonts.github.io/raw/main/fonts/NotoSansSymbols2/hinted/ttf/NotoSansSymbols2-Regular.ttf && \
    wget https://github.com/Maxattax97/gnu-freefont/raw/master/ttf/FreeSans.ttf && \
    wget https://github.com/impallari/DancingScript/raw/master/OFL.txt

RUN fontforge -lang=py -c 'font1 = fontforge.open("FreeSans.ttf"); font2 = fontforge.open("NotoSansSymbols2-Regular.ttf"); font1.mergeFonts(font2); font1.generate("FreeSans.ttf")'

FROM ruby:3.3.4-alpine as app

ENV RAILS_ENV=production
ENV BUNDLE_WITHOUT="development:test"
ENV LD_PRELOAD=/lib/libgcompat.so.0
ENV OPENSSL_CONF=/app/openssl_legacy.cnf
ENV NODE_ENV=production

WORKDIR /app

# Install system dependencies
RUN echo '@edge https://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories && \
    apk add --no-cache \
    nodejs \
    yarn \
    git \
    build-base \
    python3 \
    postgresql-dev \
    postgresql-client \
    sqlite-dev \
    mariadb-dev \
    vips-dev \
    vips-poppler \
    poppler-utils \
    redis \
    libheif@edge \
    vips-heif \
    gcompat \
    ttf-freefont \
    libpq-dev \
    tzdata \
    && mkdir /fonts \
    && rm -f /usr/share/fonts/freefont/FreeSans.otf

# Configure OpenSSL
RUN echo $'.include = /etc/ssl/openssl.cnf\n\
\n\
[provider_sect]\n\
default = default_sect\n\
legacy = legacy_sect\n\
\n\
[default_sect]\n\
activate = 1\n\
[legacy_sect]\n\
activate = 1' >> /app/openssl_legacy.cnf

# Ensure public/packs directory exists
RUN mkdir -p /app/public/packs && chmod -R 777 /app/public/packs

# Copy application code
COPY . .

# Clean and verify yarn setup
RUN rm -rf node_modules yarn.lock && \
    echo "=== Node version ===" && \
    node -v && \
    echo "=== Yarn version ===" && \
    yarn -v

# Install specific version of shakapacker and other dependencies
RUN yarn add shakapacker@8.0.2 --exact && \
    yarn install --frozen-lockfile --network-timeout 600000 && \
    echo "=== Verifying shakapacker installation ===" && \
    yarn list shakapacker

# Configure bundler and install gems
RUN bundle config build.pg --with-pg-config=/usr/bin/pg_config && \
    bundle install && \
    rm -rf ~/.bundle /usr/local/bundle/cache && \
    ruby -e "puts Dir['/usr/local/bundle/**/{spec,rdoc,resources/shared,resources/collation,resources/locales}']" | xargs rm -rf

# First compile webpack assets
RUN echo "=== Compiling webpack assets ===" && \
    NODE_ENV=production RAILS_ENV=production yarn run webpack --config config/webpack/webpack.config.js --mode=production && \
    echo "=== Webpack compilation complete ==="

# Then run asset precompilation
RUN echo "=== Starting asset precompilation ===" && \
    RAILS_ENV=production NODE_ENV=production bundle exec rake assets:precompile --trace && \
    echo "=== Asset precompilation complete ===" && \
    echo "=== Checking compiled assets ===" && \
    ls -la public/packs/ && \
    echo "=== Manifest content ===" && \
    cat public/packs/manifest.json

# Copy fonts
COPY --from=fonts /fonts/GoNotoKurrent-Regular.ttf /fonts/GoNotoKurrent-Bold.ttf /fonts/DancingScript-Regular.otf /fonts/OFL.txt /fonts
COPY --from=fonts /fonts/FreeSans.ttf /usr/share/fonts/freefont

# Link fonts directory
RUN ln -s /fonts /app/public/fonts

# Precompile bootsnap
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# Set up workdir for application
WORKDIR /data/docuseal
ENV WORKDIR=/data/docuseal

# Expose port
EXPOSE 3000

# Start command
CMD /app/bin/bundle exec puma -C /app/config/puma.rb --dir /app