#
# nZEDb Dockerfile
#

# Use baseimage-docker
FROM phusion/baseimage:0.9.13

# Set maintainer
MAINTAINER paulbarrett <https://github.com/paultbarrett/nzedb-docker>

# Set correct environment variables.
ENV TZ Europe/London
ENV HOME /root
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV TERM xterm

# Regenerate SSH host keys.
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Configure SSH access to container
RUN \
  sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config && \
  sed -i 's,^#HostKey /etc/ssh_host_rsa_key,HostKey /etc/ssh/ssh_host_rsa_key,' /etc/ssh/sshd_config && \
  sed -i 's,^#HostKey /etc/ssh_host_dsa_key,HostKey /etc/ssh/ssh_host_dsa_key,' /etc/ssh/sshd_config && \
  sed -i 's/^#LoginGraceTime 2m/LoginGraceTime 2m/' /etc/ssh/sshd_config && \
  sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
  sed -i 's/^#StrictModes yes/StrictModes yes/' /etc/ssh/sshd_config && \
  sed -i 's/^#RSAAuthentication yes/RSAAuthentication yes/' /etc/ssh/sshd_config && \
  sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
  sed -i 's,^#AuthorizedKeysFile.*,AuthorizedKeysFile  .ssh/authorized_keys,' /etc/ssh/sshd_config

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Make sure system is up-to-date.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  sed -i 's#http://archive.ubuntu.com/ubuntu#http://mirror.aarnet.edu.au/pub/ubuntu/archive#g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get -y dist-upgrade && \
  locale-gen en_US.UTF-8

# Install base software.
RUN apt-get install -y curl git htop man htop nmon vnstat tcptrack bwm-ng mytop software-properties-common python-software-properties unzip vim wget tmux ntp ntpdate time

# Install ffmpeg, mediainfo, p7zip-full, unrar and lame.
RUN \
  curl http://ffmpeg.gusari.org/static/64bit/ffmpeg.static.64bit.latest.tar.gz | tar xfvz - -C /usr/local/bin && \
  apt-get install -y unrar-free lame mediainfo p7zip-full

# Install MariaDB.
#RUN \
#  apt-get install -y mariadb-server mariadb-client libmysqlclient-dev && \
#  sed -i 's/^max_allowed_packet.*/max_allowed_packet = 16M/' /etc/mysql/my.cnf && \
#  sed -i '/key_buffer.*/a group_concat_max_len = 8192' /etc/mysql/my.cnf && \
#  sed -i 's/^key_buffer.*/key_buffer = 256M/' /etc/mysql/my.cnf && \
#  sed -i '/key_buffer.*/a key_buffer_size = 256M' /etc/mysql/my.cnf && \
#  sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/my.cnf
  
  
# Install Python MySQL modules.
RUN \
  apt-get install -y python-setuptools software-properties-common python3-setuptools python3-pip python-pip && \
  python -m easy_install pip && \
  easy_install cymysql && \
  easy_install pynntp && \
  easy_install socketpool && \
  pip list && \
  python3 -m easy_install pip && \
  pip3 install cymysql && \
  pip3 install pynntp && \
  pip3 install socketpool && \
  pip3 list

# Install PHP.
RUN \
  add-apt-repository ppa:ondrej/php && \
  apt-get update && \
  apt-get install -y \
  php5.6 \
  php5.6-cli \
  php5.6-dev \
  php5.6-fpm \
  php5.6-json \
  php-pear \
  php5.6-gd \
  php5.6-mysql \
  php5.6-pdo \
  php5.6-curl \
  php5.6-common \
  php5.6-mcrypt \
  php5.6-mbstring \
  php5.6-xml

# Configure PHP
RUN \
  sed -ri 's/(max_execution_time =) ([0-9]+)/\1 120/' /etc/php/5.6/cli/php.ini && \
  sed -ri 's/(memory_limit =) ([0-9]+)/\1 -1/'  /etc/php/5.6/cli/php.ini && \
  sed -ri 's/;(date.timezone =)/\1 Europe\/London/'  /etc/php/5.6/cli/php.ini && \
  sed -ri 's/(max_execution_time =) ([0-9]+)/\1 120/' /etc/php/5.6/fpm/php.ini && \
  sed -ri 's/(memory_limit =) ([0-9]+)/\1 1024/'  /etc/php/5.6/fpm/php.ini && \
  sed -ri 's/;(date.timezone =)/\1 Europe\/London/' /etc/php/5.6/fpm/php.ini && \
  mkdir /run/php && \
  chmod -R 777 /var/lib/php/sessions && \
  sed -i 's/^listen =.*/listen = 127.0.0.1:9000/' /etc/php/5.6/fpm/pool.d/www.conf
  

# Install simple_php_yenc_decode.
RUN \
  cd /tmp && \
  git clone https://github.com/kevinlekiller/simple_php_yenc_decode.git && \
  cd simple_php_yenc_decode/source/ && \
  apt-get install -y swig libboost-regex-dev g++

RUN \
  cd /tmp/simple_php_yenc_decode/source/ && \
  swig -php -c++ yenc_decode.i && \
  g++ `php-config5.6 --includes` -fpic -c yenc_decode_wrap.cpp && \
  g++ -fpic -c yenc_decode.cpp -lboost_rege && \
  g++ -shared *.o -o simple_php_yenc_decode.so -lboost_regex && \
  cd ~ && \
  rm -rf /tmp/simple_php_yenc_decode/

# Install memcached.
RUN apt-get install -y memcached

# Install and configure nginx.
RUN \
  apt-get install -y nginx && \
  echo '\ndaemon off;' >> /etc/nginx/nginx.conf && \
  chown -R www-data:www-data /var/lib/nginx && \
  mkdir -p /var/log/nginx && \
  chmod 755 /var/log/nginx
ADD nZEDb /etc/nginx/sites-available/nZEDb
RUN \
  unlink /etc/nginx/sites-enabled/default && \
  ln -s /etc/nginx/sites-available/nZEDb /etc/nginx/sites-enabled/nZEDb

# Setup the Composer installer.
RUN \
  curl -o /tmp/composer-setup.php https://getcomposer.org/installer && \
  curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig && \
  php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" && \
  cd /tmp && \
  php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Clone nZEDb master and set directory permissions
#RUN \
#  mkdir /var/www && \
#  cd /var/www && \
#  git clone https://github.com/nZEDb/nZEDb.git && \
#  chown www-data:www-data nZEDb/www -R && \
#  cd /var/www/nZEDb && \
#  composer install --no-dev --prefer-source && \
#  chmod -R 777 /var/www/nZEDb
  
# Add services.
RUN mkdir /etc/service/nginx
ADD nginx.sh /etc/service/nginx/run
RUN mkdir /etc/service/php5-fpm && mkdir /var/log/php5-fpm
ADD php5-fpm.sh /etc/service/php5-fpm/run
#RUN mkdir /etc/service/mariadb
#ADD mariadb.sh /etc/service/mariadb/run

# Add nZEDb.sh to execute during container startup
RUN mkdir -p /etc/my_init.d
ADD nZEDb.sh /etc/my_init.d/nZEDb.sh

# Install SSH key.
ADD id_rsa.pub /tmp/key.pub
RUN cat /tmp/key.pub >> /root/.ssh/authorized_keys && rm -f /tmp/key.pub

# Update SSL CA bundles
RUN \
  update-ca-certificates && \
  cd /etc/ssl/certs/ && \
  wget https://curl.haxx.se/ca/cacert.pem && \
  chmod -R 777 *

# Define mountable directories
VOLUME ["/etc/nginx/sites-enabled", "/var/log", "/var/www/nZEDb", "/var/lib/mysql"]

# Expose ports
EXPOSE 8810

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
