#!/bin/bash

export COMPOSER_HOME=/root
export TERM=xterm

cd /tmp
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/local/bin/composer

if [[ ! -e /var/www/nZEDb/www/config.php ]]; then

  echo "config.php does not exist. Cloning nZEDb..."
  mkdir /var/www
  cd /var/www
  git clone https://github.com/nZEDb/nZEDb.git

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

  cd /var/www/nZEDb
  composer install --prefer-source

fi

mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql

if [[ -e /var/www/nZEDb/nzedb/config/config.php ]]; then

  croncmd="/usr/bin/php /var/www/nZEDb/cli/data/predb_import_daily_batch.php progress remote false"
  cronjob="0 7 * * * $croncmd"

  (crontab -l | grep -v "$croncmd" ; echo "$cronjob" ) | crontab -

  $croncmd

  cd /var/www/nZEDb/misc/update/nix/screen/threaded
  exec sh start.sh

fi
