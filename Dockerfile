# Composer
FROM composer:2.7.7 as build-composer

WORKDIR /app
COPY src/composer.json /app/composer.json
COPY src/composer.lock /app/composer.lock

RUN composer install --ignore-platform-reqs --no-scripts --no-autoloader
COPY src /app
RUN composer dump-auto

# Image for POD
FROM php:8.2-fpm-alpine

RUN apk update && apk upgrade
RUN apk --no-cache add curl libressl-dev icu-dev icu-libs npm
RUN docker-php-ext-install  bcmath mysqli pdo_mysql intl

# xDebug:
ARG INSTALL_XDEBUG=false

RUN if [ ${INSTALL_XDEBUG} = true ]; then \
  apk add --no-cache $PHPIZE_DEPS \
  && pecl install xdebug \
  && docker-php-ext-enable xdebug \
  ;fi
COPY php-fpm/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

ARG UID
ARG GID
RUN if [ ! -z "$UID" ]; then \
  echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories \
  && apk --no-cache add shadow \
  && usermod -u $UID www-data \
  && groupmod -g $GID www-data \
  ;fi

# php.ini
COPY php-fpm/php.ini /usr/local/etc/php/php.ini

WORKDIR /app

COPY --chown=www-data:www-data src /app
COPY --chown=www-data:www-data --from=build-composer /app/vendor /app/vendor


