FROM composer:2 as composer

FROM php:7.4-apache as php

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        s3fs \
        npm \
        git \
        memcached \
# Used by composer
        unzip \
    && rm -rf /var/lib/apt/lists/*

# https://github.com/mlocati/docker-php-extension-installer
# Turns out the uopz release broke compat
# https://github.com/mlocati/docker-php-extension-installer/pull/399
# Once PR is merged lets install from docker image, https://github.com/mlocati/docker-php-extension-installer#copying-the-script-from-a-docker-image
# ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/bd7fcd4795766ed92cfd4062199339a7934eded3/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions \
    && install-php-extensions \
        sockets \
        memcached  \
        apcu \
##<php-71>##
        mcrypt \
##</php-71>##
        intl  \
        opcache \
        pcntl \
        soap \
        pdo_mysql \
        mysqli \
        xdebug \
        zip \
        calendar

RUN npm install --global bower

RUN echo "apc.enable_cli=1" >> "$PHP_INI_DIR/conf.d/0-apcu.ini" \
    && echo "memory_limit=512M" > "$PHP_INI_DIR/conf.d/memory.ini" \
    && echo "opcache.max_accelerated_files=20000" > "$PHP_INI_DIR/conf.d/perf.ini" \
    && echo "date.timezone=UTC" > "$PHP_INI_DIR/conf.d/timezone.ini" \
    && echo "allow_url_include=Off" > "$PHP_INI_DIR/conf.d/security.ini" \
    && echo "display_startup_errors=Off" >> "$PHP_INI_DIR/conf.d/security.ini" \
    && echo "display_errors=Off" >> "$PHP_INI_DIR/conf.d/security.ini" \
    && echo "expose_php=Off" >> "$PHP_INI_DIR/conf.d/security.ini" \
    && echo "log_errors=On" >> "$PHP_INI_DIR/conf.d/security.ini" \
    && echo "error_reporting=E_ALL" >> "$PHP_INI_DIR/conf.d/security.ini" \
    && echo "short_open_tag=Off" >> "$PHP_INI_DIR/conf.d/security.ini" \
    && echo "post_max_size=128m" >> "$PHP_INI_DIR/conf.d/general.ini" \
    && echo "upload_max_filesize=128m" >> "$PHP_INI_DIR/conf.d/general.ini" \
    && echo "session.save_path=/tmp" >> "$PHP_INI_DIR/conf.d/general.ini" \
    && echo "error_log=/dev/stdout" >> "$PHP_INI_DIR/conf.d/general.ini" \
    && echo "xdebug.idekey=PHPSTORM" >> /usr/local/etc/php/conf.d/debug.ini


ENV APP_STREAM_LOG php://stdout

COPY --from=composer /usr/bin/composer /usr/local/bin/composer
RUN adduser --system --disabled-password --disabled-login --group composer

USER root
#WORKDIR /srv/project

##<apache>##
RUN a2enmod rewrite \
  && a2enmod headers \
  && a2enmod ssl \
  && a2enmod deflate

ENV REDIS_URL ""
ENV APACHE_DOCUMENT_ROOT /srv/project/public
ENV APACHE_DOCUMENT_ALIAS ""
ENV APACHE_VIRTUAL_HOST_EXTRA ""
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data

