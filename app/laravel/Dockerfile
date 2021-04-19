# FROM php:7.3-fpm-alpine

# ARG UID=991
# ARG UNAME=www
# ARG GID=991
# ARG GNAME=www

# ENV WORKDIR=/var/www/html
# WORKDIR $WORKDIR

# COPY ./docker/php/php.ini /usr/local/etc/php
# COPY composer.json composer.lock ${WORKDIR}/

# RUN set -x \
#     && apk add --no-cache git php7-zlib zlib-dev libzip-dev \
#     && docker-php-ext-install pdo_mysql zip \
#     && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
#     && composer install --no-autoloader --no-progress --no-dev

# COPY . .
# COPY entrypoint.sh /var/tmp/entrypoint.sh
# RUN chmod 777 /var/tmp/entrypoint.sh

# RUN set -x \
#     && composer install --no-progress --no-dev \
#     && php artisan config:clear \
#     && addgroup ${GNAME} -g ${GID} \
#     && adduser -D -G ${GNAME} -u ${UID} ${UNAME} \
#     && chown -R ${UNAME}:${GNAME} ${WORKDIR} \
#     && mv /root/.composer /home/${UNAME}/ \
#     && chown -R ${UNAME}:${GNAME} /home/${UNAME}

# USER ${UNAME}

# ENTRYPOINT [ "/var/tmp/entrypoint.sh" ]

FROM centos:7

ARG UID=991
ARG UNAME=www
ARG GID=991
ARG GNAME=www
ARG ENCRYPT_KEY

ENV WORKDIR=/var/www/html
ENV ENCRYPT_KEY=${ENCRYPT_KEY}
WORKDIR $WORKDIR

RUN yum update -y \
    && yum install -y yum-utils epel-release https://rpms.remirepo.net/enterprise/remi-release-7.rpm \
    && yum-config-manager --disable epel

RUN yum install -y --enablerepo=epel,remi-php73 \
    zip \
    unzip \
    php \
    php-fpm \
    php-mbstring \
    php-pear \
    php-mcrypt \
    php-cli \
    php-common \
    php-json \
    php-mysqld \
    php-pdo \
    php-process \
    php-xml \
    php-pecl-mysql.x86_64 \
    php-devel \
    php-pecl-zip \
    php-gd \
    libwebp-devel \
    scl-utils \
    cronie-noanacron \
    git \
    php7-zlib \
    zlib-dev \
    libzip-dev \
    docker-php-ext-install \
    zip \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY ./docker/php/www.conf /etc/php-fpm.d/www.conf
COPY ./docker/php/www.conf.local /etc/php-fpm.d/www.conf.local

COPY ./docker/php/php.ini /usr/local/etc/php
COPY composer.json composer.lock ${WORKDIR}/

RUN mkdir /run/php-fpm \
    && composer install --no-autoloader --no-progress --no-dev

COPY . .
COPY entrypoint.sh /var/tmp/entrypoint.sh

RUN set -x \
    && composer install --no-progress \
    && php artisan config:clear \
    && php artisan key:generate \
    && php artisan config:cache \
    && chmod +x /var/tmp/entrypoint.sh \
    && groupadd --gid ${GID} ${GNAME} \
    && useradd -m -u ${UID} -g ${GID} ${UNAME} \
    && chown -R ${UNAME}:${GNAME} ${WORKDIR} \
    && chown -R ${UNAME}:${GNAME} /home/${UNAME}

USER ${UNAME}

ENTRYPOINT [ "/var/tmp/entrypoint.sh" ]