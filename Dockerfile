FROM php:5.6-fpm

# curl mbstring json - in base image exist
# mysql extension (deprecated) required for testrail
RUN docker-php-ext-install mysql

RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/*
#RUN apt-get update && apt-get -y install --no-install-recommends zlib1g-dev libxml2-dev
# for testrail background task
#RUN docker-php-ext-install zip
# for bugzilla defect plugin
#RUN docker-php-ext-install xmlrpc

RUN set -ex \
	&& apt-get update \
	&& apt-get install -y libldap2-dev \
	&& rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu \
	&& docker-php-ext-install ldap

RUN set -ex \
	&& curl -fsSL 'http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz' -o ioncube.tar.gz \
	&& mkdir -p ioncube \
	&& tar xzvf ioncube.tar.gz -C ioncube --strip-components=1 \
	&& mv ioncube/ioncube_loader_lin_5.6.so /usr/local/lib/php/extensions/* \
#       && docker-php-ext-enable ioncube_loader_lin_5.6 \
	&& echo "zend_extension=ioncube_loader_lin_5.6.so" > /usr/local/etc/php/conf.d/docker-php-ext-ioncube_loader_lin_5.6.ini \
	&& rm -Rf ioncube.tar.gz ioncube 

RUN set -ex \
	&& curl -fsSL 'http://www.gurock.com/downloads/testrail/testrail-latest-ion70.zip' -o /tmp/testrail.zip \
	&& unzip /tmp/testrail.zip -d /tmp \
	&& mv /tmp/testrail/* /var/www/html/ \
	&& rm -Rf /tmp/testrail.zip /tmp/testrail/ \
	&& mkdir -p /var/www/html/logs \
	&& chown -R www-data:www-data /var/www/html/ \
	&& mkdir -p /opt/testrail/attachments/ && mkdir -p /opt/testrail/reports/ \
	&& chown -R www-data:www-data /opt/testrail/ 

RUN set -ex \
	&& apt-get update \
	&& apt-get install --no-install-recommends -y cron \
	&& echo '* * * * * root echo "`date` - test cron job" > /proc/1/fd/1' >> /etc/cron.d/testrail \
	&& echo '* * * * * www-data /usr/local/bin/php /var/www/html/task.php' >> /etc/cron.d/testrail && chmod +x /etc/cron.d/testrail \
	&& rm -rf /var/lib/apt/lists/*

RUN php -m

VOLUME /opt/testrail/	 
