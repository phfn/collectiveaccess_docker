FROM ubuntu:24.04

ENV APACHE_RUN_USER     www-data
ENV APACHE_RUN_GROUP    www-data
ENV APACHE_LOG_DIR      /var/log/apache2
ENV APACHE_PID_FILE     /var/run/apache2.pid
ENV APACHE_RUN_DIR      /var/run/apache2
ENV APACHE_LOCK_DIR     /var/lock/apache2
ENV APACHE_LOG_DIR      /var/log/apache2

ENV CA_PROVIDENCE_VERSION=2.0.11
ENV CA_PROVIDENCE_DIR=/var/www/providence
ENV CA_PAWTUCKET_VERSION=2.0.11
ENV CA_PAWTUCKET_DIR=/var/www

ENV PHP_VERSION="8.3"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y apache2 \
	curl \
	wget \
	zip \
	php${PHP_VERSION} \
	php${PHP_VERSION}-cli \
	php${PHP_VERSION}-gd \
	php${PHP_VERSION}-curl \
	php${PHP_VERSION}-mysqli \
	php${PHP_VERSION}-zip \
	php${PHP_VERSION}-xml \
	php${PHP_VERSION}-mbstring \
	php${PHP_VERSION}-intl \
	php${PHP_VERSION}-bcmath \
	php${PHP_VERSION}-gmp \
	php${PHP_VERSION}-opcache \
	php${PHP_VERSION}-ldap \
	php${PHP_VERSION}-gmagick \
	libapache2-mod-php${PHP_VERSION} \
	mysql-client \
	ffmpeg \
	ghostscript \
	imagemagick \
	libreoffice

RUN curl -SsL https://github.com/collectiveaccess/providence/archive/$CA_PROVIDENCE_VERSION.tar.gz | tar -C /var/www/ -xzf -
RUN mv /var/www/providence-$CA_PROVIDENCE_VERSION /var/www/providence
RUN cd $CA_PROVIDENCE_DIR && cp setup.php-dist setup.php

RUN curl -SsL https://github.com/collectiveaccess/pawtucket2/archive/$CA_PAWTUCKET_VERSION.tar.gz | tar -C /var/www/ -xzf -
RUN mv $CA_PAWTUCKET_DIR/pawtucket2-$CA_PAWTUCKET_VERSION/* /var/www
RUN cd $CA_PAWTUCKET_DIR && cp setup.php-dist setup.php

RUN sed -i "s@DocumentRoot \/var\/www\/html@DocumentRoot \/var\/www@g" /etc/apache2/sites-available/000-default.conf
RUN rm -rf /var/www/html
RUN ln -s /$CA_PROVIDENCE_DIR/media /$CA_PAWTUCKET_DIR/media

RUN chown -R www-data:www-data /var/www

# Create a backup of the default conf files in case directory is mounted
RUN mkdir -p /var/ca/providence/conf
RUN cp -r /$CA_PROVIDENCE_DIR/app/conf/* /var/ca/providence/conf

# Copy our local files
COPY php.ini /etc/php/${PHP_VERSION}/apache2/php.ini
COPY entrypoint.sh /entrypoint.sh
RUN chmod 777 /entrypoint.sh

# Install Composer
RUN apt-get update && apt-get install -y composer
RUN cd /var/www/providence && rm *.lock && composer install --no-interaction --prefer-dist

# Run apcache from entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 80
CMD ["apache2ctl", "-D", "FOREGROUND"]
