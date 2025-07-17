# Build frontend with pnpm
FROM node:18-bookworm as pnpm-build

WORKDIR /pinry-spa
COPY pinry-spa/package.json pinry-spa/pnpm-lock.yaml ./
RUN npm install -g pnpm
RUN pnpm install
COPY pinry-spa .
RUN pnpm build

# Python base image
FROM python:3.11-slim as base
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get -y install build-essential libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Final image
FROM python:3.11-slim
ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /pinry
RUN mkdir /data && chown -R www-data:www-data /data

RUN groupadd -g 2300 tmpgroup \
 && usermod -g tmpgroup www-data \
 && groupdel www-data \
 && groupadd -g 1000 www-data \
 && usermod -g www-data www-data \
 && usermod -u 1000 www-data \
 && groupdel tmpgroup

RUN apt-get update \
    # Install nginx
    && apt-get -y install nginx pwgen \
    # Install Pillow dependencies
    && apt-get -y install libopenjp2-7 libjpeg-turbo-progs libjpeg62-turbo-dev libtiff5-dev libxcb1 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoclean

# Install Python dependencies
COPY requirements-dev.txt ./
RUN pip install --no-cache-dir -r requirements-dev.txt

# Copy frontend build
COPY --from=pnpm-build /pinry-spa/dist /pinry/pinry-spa/dist

# Copy project files
COPY . .

# Load in all of our config files.
ADD docker/nginx/nginx.conf /etc/nginx/nginx.conf
ADD docker/nginx/sites-enabled/default /etc/nginx/sites-enabled/default

# Expose the port Railway provides
EXPOSE ${PORT}
ENV DJANGO_SETTINGS_MODULE pinry.settings.docker

# Start script (should handle migrations, collectstatic, gunicorn, nginx, and use $PORT)
CMD ["/pinry/docker/scripts/start.sh"]
