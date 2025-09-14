FROM ruby:3.2-slim-bookworm

# Environment setup
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies
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
    shared-mime-info \
    iputils-ping \
 && rm -rf /var/lib/apt/lists/*

# Enable Corepack (for Yarn/PNPM)
RUN corepack enable

# Prepare Huginn build environment
