##################################
#=== Single stage with payload ===
##################################
FROM php:7.3-apache

#=== Install gd php dependencie ===
RUN set -x \
 && runtimeDeps="libfreetype6 libjpeg62-turbo" \
 && buildDeps="libpng-dev libjpeg-dev libfreetype6-dev" \
 && apt-get update && apt-get install -y ${buildDeps} ${runtimeDeps} --no-install-recommends \
 \
 && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
 && docker-php-ext-install gd \
 \
 && apt-get autoremove -y ${buildDeps} \
 && rm -rf /var/lib/apt/lists/*

#=== Install ldap php dependencie ===
RUN set -x \
 && buildDeps="libldap2-dev" \
 && apt-get update && apt-get install -y ${buildDeps} --no-install-recommends \
 \
 && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
 && docker-php-ext-install ldap \
 \
 && apt-get autoremove -y ${buildDeps} \
 && rm -rf /var/lib/apt/lists/*

#=== Install intl php dependencie ===
RUN set -x \
 && runtimeDeps="libicu63" \
 && buildDeps="libicu-dev" \
 && apt-get update && apt-get install -y ${buildDeps} ${runtimeDeps} --no-install-recommends \
 \
 && docker-php-ext-configure intl \
 && docker-php-ext-install intl \
 \
 && apt-get autoremove -y ${buildDeps} \
 && rm -rf /var/lib/apt/lists/*


#=== Install zip, soap and opcache php dependencies ===
RUN set -x \
 && buildDeps="libxml2-dev zlib1g-dev libzip-dev" \
 && apt-get update && apt-get install -y ${buildDeps} --no-install-recommends \
 \
 && docker-php-ext-install zip \
 && docker-php-ext-install soap \
 && docker-php-ext-install opcache \
 \
 && apt-get autoremove -y ${buildDeps} \
 && rm -rf /var/lib/apt/lists/*

  #=== Install mysqli php dependencie ===
RUN set -x \
 && buildDeps="zlib1g-dev libpng-dev" \
 && apt-get update && apt-get install -y ${buildDeps} --no-install-recommends \
 \
 && docker-php-ext-install gd mysqli \
 && apt-get autoremove -y ${buildDeps} \
 && rm -rf /var/lib/apt/lists/*

#=== Install mcrypt php dependencie ===
RUN set -x \
 && runtimeDeps="libmcrypt4" \
 && buildDeps="libmcrypt-dev libzip-dev" \
 && apt-get update && apt-get install -y ${runtimeDeps} ${buildDeps} --no-install-recommends \
 \
 && pecl install mcrypt-1.0.2 \
 && docker-php-ext-enable  mcrypt \
 \
 && apt-get autoremove -y ${buildDeps} \
 && rm -rf /var/lib/apt/lists/*

#=== Install graphviz ===
RUN set -x \
 && apt-get update && apt-get install -y graphviz --no-install-recommends \
 && rm -rf /var/lib/apt/lists/*


#=== Set app folder ===
ARG APP_NAME="itop"
WORKDIR /var/www/$APP_NAME

#=== Add iTop source code ===
ARG ITOP_VERSION=2.7.4
ARG ITOP_PATCH=7194
RUN set -x \
 && buildDeps="bsdtar" \
 && apt-get update && apt-get install -y ${buildDeps} --no-install-recommends \
 \
 && curl -sL https://sourceforge.net/projects/itop/files/itop/$ITOP_VERSION/iTop-$ITOP_VERSION-$ITOP_PATCH.zip \
  | bsdtar --strip-components=1 -xf- web \
 \
 && apt-get autoremove -y ${buildDeps} \
 && rm -rf /var/lib/apt/lists/*

#=== Apache vhost ===
RUN { \
  echo "<VirtualHost *:80>"; \
  echo "DocumentRoot /var/www/$APP_NAME"; \
  echo; \
  echo "<Directory /var/www/$APP_NAME>"; \
  echo "\tOptions -Indexes"; \
  echo "\tAllowOverride all"; \
  echo "</Directory>"; \
  echo "</VirtualHost>"; \
 } | tee "$APACHE_CONFDIR/sites-available/$APP_NAME.conf" \
 && set -x \
 && a2dissite 000-default \
 && a2ensite $APP_NAME \
 && a2enmod headers \
 && echo "ServerName $APP_NAME" >> $APACHE_CONFDIR/apache2.conf

#=== Apache security ===
RUN { \
  echo 'ServerTokens Prod'; \
  echo 'ServerSignature Off'; \
  echo 'TraceEnable Off'; \
  echo 'Header set X-Content-Type-Options: "nosniff"'; \
  echo 'Header set X-Frame-Options: "sameorigin"'; \
 } | tee $APACHE_CONFDIR/conf-available/security.conf \
 && set -x \
 && a2enconf security

#=== php default ===
ENV PHP_TIMEZONE="Europe/Moscow" \
    PHP_ENABLE_UPLOADS=On \
    PHP_MEMORY_LIMIT=64M \
    PHP_POST_MAX_SIZE=10M \
    PHP_UPLOAD_MAX_FILESIZE=8M \
    PHP_MAX_FILE_UPLOADS=20 \
    PHP_MAX_INPUT_TIME=300 \
    PHP_LOG_ERRORS=On \
    PHP_ERROR_REPORTING=E_ALL



#=== Set custom entrypoint ===
COPY docker-entrypoint.sh /entrypoint
RUN chmod +x /entrypoint
ENTRYPOINT [ "/entrypoint" ]

#=== Re-Set CMD as we changed the default entrypoint ===
CMD [ "apache2-foreground" ]
