FROM ruby:3.2-bookworm

# Set environment variables
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    RAILS_ENV=production \
    APP_SECRET_TOKEN=secret \
    DATABASE_ADAPTER=mysql2 \
    ON_HEROKU=true

# Install essential system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    libmysqlclient-dev \
    libsqlite3-dev \
    zlib1g-dev \
    libyaml-dev \
    libssl-dev \
    libgdbm-dev \
    libreadline-dev \
    libncurses5-dev \
    libffi-dev \
    libxml2-dev \
    libxslt-dev \
    curl \
    gnupg \
    git \
    locales \
    tzdata \
    nodejs \
 && rm -rf /var/lib/apt/lists/*

# Enable Corepack for Yarn
RUN corepack enable

# Copy and run Huginn prepare script
COPY docker/scripts/prepare /scripts/
RUN sed -i 's/git-core/git/' /scripts/prepare \
 && sed -i 's/apt-get purge -y python3\*/# removed python3 purge/' /scripts/prepare \
 && /scripts/prepare

# Copy and run standalone packages script
COPY docker/multi-process/scripts/standalone-packages /scripts/
RUN /scripts/standalone-packages

# Set working directory
WORKDIR /app

# Copy Ruby dependencies
COPY ["Gemfile", "Gemfile.lock", "/app/"]
COPY lib/gemfile_helper.rb /app/lib/
COPY vendor/gems/ /app/vendor/gems/

# Install Ruby gems
RUN umask 002 && git init && \
    bundle config set --local path vendor/bundle && \
    bundle config set --local without 'test development' && \
    bundle install -j 4

# Copy full Huginn application
COPY ./ /app/

ARG OUTDATED_DOCKER_IMAGE_NAMESPACE=false
ENV OUTDATED_DOCKER_IMAGE_NAMESPACE=${OUTDATED_DOCKER_IMAGE_NAMESPACE}

# Precompile assets
RUN umask 002 && \
    bundle exec rake assets:clean assets:precompile && \
    chmod g=u /app/.env.example /app/Gemfile.lock /app/config/ /app/tmp/

# Expose Rails port
EXPOSE 3000

# Supervisor configs
COPY docker/multi-process/scripts/supervisord.conf /etc/supervisor/
COPY ["docker/multi-process/scripts/bootstrap.conf", \
      "docker/multi-process/scripts/foreman.conf", \
      "docker/multi-process/scripts/mysqld.conf", "/etc/supervisor/conf.d/"]
COPY ["docker/multi-process/scripts/bootstrap.sh", \
      "docker/multi-process/scripts/foreman.sh", \
      "docker/multi-process/scripts/init", \
      "docker/scripts/setup_env", "/scripts/"]

CMD ["/scripts/init"]

# Create non-root user
ARG UID=1001
RUN useradd -u "$UID" -g 0 -d /app -s /sbin/nologin -c "default user" default
USER $UID
ENV HOME=/app

# Persistent MySQL volume
VOLUME /var/lib/mysql
