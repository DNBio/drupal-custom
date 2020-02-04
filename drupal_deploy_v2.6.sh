#!/bin/bash
# EHESS 2018 / Drupal 8 custom setup script
# David N. Brett - EHESS
#
# This script expects the following to be up and running on the server
# 
# - PHP 7.X (with PECL)
# - MySQL >= 5.7
# - PostFix
# - Redis
# - Git
# - PERL
# - OpenSSL
# - PECL uploadprogress

# FQDN for trusted hosts parameter.
DOMAIN_NAME="domain.com"

# Allow webserver access to specific directories via the Apache2 user.
APACHE_USER="www-data"
APACHE_GROUP="www-data"

# If we operate behind a proxy...
# If not set USE_PROXY to false
USE_PROXY=false
PROXY_SERVER=""
PROXY_PORT=""

# Where to store the drupal install.
# This dir will contain the new project.
DRUPAL_MASTER_DIR="master"

# Drupal project name
# e.g. "drupal"
DRUPAL_INSTALL_NAME="drupal"

# Drupal web root name
# e.g. "web"
DRUPAL_WEB_ROOT_NAME="web"

# Database and assigned user must be created prior to running this script
# MySQL Credentials
DB_NAME=""
DB_USER=""
DB_PASS=""
DB_HOST=127.0.0.1
DB_PORT=3306

# DON'T !!
# Too dangerous to hardcode the SQL root access !
# Do it by hand, lazy boy.
# mysql -u root -pxxx -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
# mysql -u root -pxxx -e "CREATE USER '$DB_USER'@'$DB_HOST' IDENTIFIED BY '$DB_PASS';"
# mysql -u root -pxxx -e "GRANT ALL PRIVILEGES ON $DB_NAME . * TO '$DB_USER'@'$DB_HOST';"
# mysql -u root -pxxx -e "FLUSH PRIVILEGES;"

# Presets composer file
BASE_COMPOSER_FILE="$PWD/composer.json"

# create the directory if it doesn't exist, 
# but warn you if the name of the directory you're trying 
# to create is already in use by something other than a directory.
#if [[ ! -e $DRUPAL_MASTER_DIR ]]; then
#    mkdir $DRUPAL_MASTER_DIR
#elif [[ ! -d $DRUPAL_MASTER_DIR ]]; then
#    echo "$DRUPAL_MASTER_DIR already exists but is not a directory" 1>&2
#fi

#DRUPAL_INSTALL_PATH="$PWD/$DRUPAL_MASTER_DIR"
#cd $DRUPAL_INSTALL_PATH

# Setup new Drupal project
#composer create-project drupal-composer/drupal-project:8.x-dev \
#$DRUPAL_INSTALL_NAME --stability dev --no-interaction


# cd in the new poject dir
cd $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME

rm $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/composer.json
rm $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/composer.lock
cp $BASE_COMPOSER_FILE $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/composer.json
composer install

# RobotsTXT module needs original robots.txt file deleted
rm $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/robots.txt

# Link composer installed libraries to Drupal libraries dir
ln -s $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/vendor/components/chosen $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/libraries/chosen
ln -s $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/vendor/components/chosen $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/libraries/jquerychosen

ln -s $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/vendor/components/highlightjs $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/libraries/highlightjs
ln -s $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/vendor/mbostock/d3 $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/libraries/d3

# Download external lib not available to composer
mkdir $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/libraries/jquery-ui-slider-pips
wget https://raw.githubusercontent.com/simeydotme/jQuery-ui-Slider-Pips/master/dist/jquery-ui-slider-pips.js  -P $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/libraries/jquery-ui-slider-pips
wget https://raw.githubusercontent.com/simeydotme/jQuery-ui-Slider-Pips/master/dist/jquery-ui-slider-pips.css  -P $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/libraries/jquery-ui-slider-pips

git clone https://github.com/fengyuanchen/cropper $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/libraries/cropper
git clone https://github.com/select2/select2.git $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/libraries/select2

# Inject database credentials into default settings file
echo "\$databases['default']['default'] = array (" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "  'database' => '$DB_NAME'," >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "  'username' => '$DB_USER'," >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "  'password' => '$DB_PASS'," >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "  'prefix' => ''," >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "  'host' => '$DB_HOST'," >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "  'port' => '$DB_PORT'," >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "  'namespace' => 'Drupal\\Core\\Database\\Driver\\mysql'," >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "  'driver' => 'mysql'," >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "  'collation' => 'utf8mb4_general_ci'," >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo ");" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php

echo "\$settings['hash_salt'] = 'IUGLYGKUFGKUFYYTFYTCGRSEZQEZWRSWRY';" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php

if [ "$USE_PROXY" = true ] ; then
    echo "\$settings['http_client_config']['proxy']['http'] = '$PROXY_SERVER:$PROXY_PORT';" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
    echo "\$settings['http_client_config']['proxy']['https'] = '$PROXY_SERVER:$PROXY_PORT';" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
fi

# Sync dir, outside web root
mkdir $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/sync
echo "\$config_directories = array(" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "CONFIG_SYNC_DIRECTORY => '$DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/sync'," >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo ");" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php

# Store weform files in private dir
mkdir $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/private_files
echo "\$settings['file_private_path'] = '$DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/private_files';" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
chown $APACHE_USER:$APACHE_GROUP -R $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/private_files

# Redis config
# Must remain commented prior to Redis module enable !
echo "/**" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo " * Redis Configuration." >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo " *" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "\$conf['chq_redis_cache_enabled'] = TRUE;" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "if (isset(\$conf['chq_redis_cache_enabled']) && \$conf['chq_redis_cache_enabled']) {" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "  \$settings['redis.connection']['interface'] = 'PhpRedis';" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "  \$settings['cache']['default'] = 'cache.backend.redis';" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "  // Note that unlike memcached, redis persists cache items to disk so we can" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "  // actually store cache_class_cache_form in the default cache." >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "  \$conf['cache_class_cache'] = 'Redis_Cache';" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "}" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "*/" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php

# Trusted hosts (Localhost and FQDN)
echo "\$settings['trusted_host_patterns'] = [" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo " '^127.0.0.1\$'," >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo " '^$DOMAIN_NAME\$'," >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php
echo "];" >> $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/settings.php

# Permissions
mkdir $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/files/translations
chown $APACHE_USER:$APACHE_GROUP -R $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/files
chmod 755 -R $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/$DRUPAL_WEB_ROOT_NAME/sites/default/files

chown $APACHE_USER:$APACHE_GROUP -R $DRUPAL_INSTALL_PATH/$DRUPAL_INSTALL_NAME/sync
