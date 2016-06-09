#!/bin/bash

export COMPOSER_HOME=/root
export TERM=xterm

chmod -R 777 /var/lib/php5

cd /tmp
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/local/bin/composer

#if [[ ! -e /var/www/nZEDb/www/config.php ]]; then

#  echo "config.php does not exist. Cloning nZEDb..."
#  mkdir /var/www
#  cd /var/www
#  git clone https://github.com/nZEDb/nZEDb.git
#  chown www-data:www-data nZEDb/www -R
#  chmod 777 /var/www/nZEDb/libs/smarty/templates_c

#  chmod -R 777 /var/www/nZEDb/resources/covers/
#  chmod -R 777 /var/www/nZEDb/resources/nzb/
#  chmod -R 777 /var/www/nZEDb/resources/tmp/unrar/

#else

if [[ -e /var/www/nZEDb/nzedb/config/config.php ]]; then

  cd /var/www/nZEDb/misc/update/nix/tmux
  exec php start.php

fi
