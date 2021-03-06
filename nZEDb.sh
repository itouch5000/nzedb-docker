#!/bin/bash

export COMPOSER_HOME=/root
export TERM=xterm

cd /tmp
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/local/bin/composer

if [[ ! -e /var/www/nZEDb/configuration/install.lock ]]; then

  echo "config.php does not exist. Cloning nZEDb..."

  mkdir /opt
  cd /opt
  git clone https://github.com/nZEDb/nZEDb.git
  mkdir /var/www
  mv /opt/nZEDb/* /var/www/nZEDb
  cd /var/www/nZEDb
  git init

  chmod -R 777 /var/www/nZEDb/resources/nzb/
  chmod -R 777 /var/www/nZEDb/resources/tmp/unrar/
  chmod -R 755 /var/www/nZEDb
  chgrp www-data /var/www/nZEDb/resources/smarty/templates_c
  chmod 775 /var/www/nZEDb/resources/smarty/templates_c
  chgrp -R www-data /var/www/nZEDb/resources/covers
  chmod -R 775 /var/www/nZEDb/resources/covers
  chgrp www-data /var/www/nZEDb/www -R
  chmod 775 /var/www/nZEDb/www
  chgrp www-data /var/www/nZEDb/www/install
  chmod 777 /var/www/nZEDb/www/install
  chgrp -R www-data /var/www/nZEDb/resources/nzb
  chmod -R 775 /var/www/nZEDb/resources/nzb
  chgrp www-data /var/www/nZEDb/configuration
  chmod -R 775 /var/www/nZEDb/configuration
  chmod 777 /var/www/nZEDb/resources/smarty/templates_c

  composer install --prefer-source

fi

#mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql

su znc -c znc

if [[ -e /var/www/nZEDb/configuration/install.lock ]]; then

  cd /var/www/nZEDb/misc/update/nix/tmux
  #exec php start.php

fi
