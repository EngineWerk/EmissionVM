#!/bin/sh

echo "192.168.56.101 emission.local" >>/etc/hosts

apt-get update
apt-get install -y python-software-properties

add-apt-repository -y ppa:ondrej/php5-oldstable
add-apt-repository -y ppa:webupd8team/java

apt-get update

export DBPASSWORD=vagrant
echo mysql-server mysql-server/root_password password vagrant | debconf-set-selections
echo mysql-server mysql-server/root_password_again password vagrant | debconf-set-selections

apt-get install -y nginx php5 mysql-server php5-mysql php5-fpm php5-curl \
   php5-dev build-essential memcached php5-memcache php5-memcached php5-xdebug php5-intl git php5-cli curl \
   vim mc htop

curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
composer selfupdate

echo "xdebug.remote_host = 192.168.56.1" >> /etc/php5/conf.d/20-xdebug.ini
echo "xdebug.remote_enable = 1" >> /etc/php5/conf.d/20-xdebug.ini
echo "xdebug.remote_port = 9000" >> /etc/php5/conf.d/20-xdebug.ini
echo "xdebug.remote_handler = dbgp" >> /etc/php5/conf.d/20-xdebug.ini
echo "xdebug.remote_mode = req" >> /etc/php5/conf.d/20-xdebug.ini

mkdir -p /var/www

ln -s /emission /var/www/emission

echo "Setting up nginx vhosts"
cp /vagrant/config/emission/emission.local.conf /etc/nginx/sites-available/

ln -s /etc/nginx/sites-available/emission.local.conf /etc/nginx/sites-enabled/

echo "Configuring Emission"
cd /var/www/emission

mkdir -p app/local_fs/binary/
chmod a+rwX app/local_fs/binary/

cp /vagrant/config/emission/parameters.yml /var/www/emission/app/config/

/etc/init.d/nginx restart

echo "Creating emission database ..."
mysql -u root -p$DBPASSWORD -e 'CREATE DATABASE emission;'

echo "Composer install"
cd /var/www/emission
composer install

echo "Granting logs and cache permission"
chmod -R 777 /var/www/emission/app/logs /var/www/emission/app/cache

echo "Grant console execution permission"
chmod a+X app/console

php app/console doctrine:schema:update --force
php app/console sessionstorage:init
php app/console fos:user:create vagrant vagrant@localhost vagrant --super-admin
php app/console fos:user:activate vagrant

mysql -u root -p$DBPASSWORD  -e "grant all privileges on *.* to 'root'@'%' identified by 'vagrant' with grant option;"
mysql -u root -p$DBPASSWORD  -e "flush privileges;"

echo "listen.owner = www-data" >> /etc/php5/fpm/pool.d/www.conf
echo "listen.group = www-data" >> /etc/php5/fpm/pool.d/www.conf
echo "listen.mode = 0660" >> /etc/php5/fpm/pool.d/www.conf

/etc/init.d/php5-fpm restart

#keeping a stable version of pear, need a 3.x (in this case is 3.7)
cp /vagrant/config/emission/phpunit-lts.phar /usr/bin/phpunit
chmod 755 /usr/bin/phpunit

#autoconfigure to allow phpstorm to debug connections properly
echo 'export XDEBUG_CONFIG="idekey=PHPSTORM remote_host=192.168.56.1 remote_port=9000"' >> /home/vagrant/.profile
#the server name should correspond to the server name you created in your project in phpstorm
echo 'export PHP_IDE_CONFIG="serverName=emission.local"' >> /home/vagrant/.profile
