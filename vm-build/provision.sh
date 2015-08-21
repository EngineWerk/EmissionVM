#!/bin/sh

apt-get update
apt-get install -y python-software-properties

add-apt-repository -y ppa:ondrej/php5

apt-get update

export DBPASSWORD=vagrant
echo mysql-server mysql-server/root_password password vagrant | debconf-set-selections
echo mysql-server mysql-server/root_password_again password vagrant | debconf-set-selections

apt-get install -y nginx php5 mysql-server php5-mysql php5-fpm php5-curl \
   php5-dev build-essential memcached php5-memcache php5-memcached php5-xdebug php5-intl git php5-cli curl \
   vim mc htop git

echo "=> Install composer"
curl -sS https://getcomposer.org/installer | php
mv /home/vagrant/composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

echo "xdebug.remote_host = 192.168.200.1" >> /etc/php5/conf.d/20-xdebug.ini
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

mkdir -p /vagrant/data/local_fs/binary/
chmod a+rwX /vagrant/data/local_fs/binary/

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

echo "=> Configuration for PHP"
sed -i "s/display_errors:.*/display_errors: On/g" /etc/php5/cli/php.ini
sed -i "s/display_errors:.*/display_errors: On/g" /etc/php5/fpm/php.ini
sed -i "s/;date.timezone =.*/date.timezone = UTC/g" /etc/php5/cli/php.ini
sed -i "s/upload_max_filesize =.*/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini
sed -i "s/post_max_size =.*/post_max_size = 101M/g" /etc/php5/fpm/php.ini
sed -i "s/file_uploads =.*/file_uploads = On/g" /etc/php5/fpm/php.ini

/etc/init.d/php5-fpm restart

#keeping a stable version of pear, need a 3.x (in this case is 3.7)
cp /vagrant/config/emission/phpunit-lts.phar /usr/bin/phpunit
chmod 755 /usr/bin/phpunit

#autoconfigure to allow phpstorm to debug connections properly
echo 'export XDEBUG_CONFIG="idekey=PHPSTORM remote_host=192.168.200.1 remote_port=9000"' >> /home/vagrant/.profile
#the server name should correspond to the server name you created in your project in phpstorm
echo 'export PHP_IDE_CONFIG="serverName=emission.local"' >> /home/vagrant/.profile

# Box shrink
/vagrant/post-provision.sh
echo 'Machine ready'