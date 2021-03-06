#!/bin/bash
if [ "$SKIP_PIWIK_TEST_PREPARE" == "1" ]; then
    echo "Skipping Matomo specific test peparation."
    exit 0;
fi

set -e

# Install woff2 if not already present
if [ ! -d "travis_woff2/src" ];
then
    echo "installing woff2..."

    rm -rf ../travis_woff2
    git clone --recursive https://github.com/google/woff2.git ../travis_woff2
    cd ../travis_woff2
    make clean all
    cd ../matomo
fi

# Install fonts for UI tests
if [ "$TEST_SUITE" = "UITests" ];
then
    mkdir $HOME/.fonts
    cp ./tests/travis/fonts/* $HOME/.fonts
    fc-cache -f -v

    echo "fonts:"
    ls $HOME/.fonts

    echo "installing node/puppeteer"

    nvm install 8 && nvm use 8
    cd ./tests/lib/screenshot-testing
    npm install
    cd $PIWIK_ROOT_DIR
fi

# Copy Piwik configuration
echo "Install config.ini.php"
sed "s/PDO\\\MYSQL/${MYSQL_ADAPTER}/g" ./tests/travis/config.ini.travis.php > ./config/config.ini.php

# Prepare phpunit.xml
echo "Adjusting phpunit.xml"
cp ./tests/PHPUnit/phpunit.xml.dist ./tests/PHPUnit/phpunit.xml

if grep "@REQUEST_URI@" ./tests/PHPUnit/phpunit.xml > /dev/null; then
    sed -i 's/@REQUEST_URI@/\//g' ./tests/PHPUnit/phpunit.xml
fi

if [ -n "$PLUGIN_NAME" ];
then
      sed -n '/<filter>/{p;:a;N;/<\/filter>/!ba;s/.*\n/<whitelist addUncoveredFilesFromWhitelist=\"true\">\n<directory suffix=\".php\">..\/..\/plugins\/'$PLUGIN_NAME'<\/directory>\n<exclude>\n<directory suffix=\".php\">..\/..\/plugins\/'$PLUGIN_NAME'\/tests<\/directory>\n<directory suffix=\".php\">..\/..\/plugins\/'$PLUGIN_NAME'\/Test<\/directory>\n<directory suffix=\".php\">..\/..\/plugins\/'$PLUGIN_NAME'\/Updates<\/directory>\n<\/exclude>\n<\/whitelist>\n/};p' ./tests/PHPUnit/phpunit.xml > ./tests/PHPUnit/phpunit.xml.new && mv ./tests/PHPUnit/phpunit.xml.new ./tests/PHPUnit/phpunit.xml
fi;

# Create tmp/ sub-directories
mkdir -p ./tmp/assets
mkdir -p ./tmp/cache
mkdir -p ./tmp/latest
mkdir -p ./tmp/logs
mkdir -p ./tmp/sessions
mkdir -p ./tmp/templates_c
mkdir -p ./tmp/tcpdf
mkdir -p ./tmp/climulti
chmod a+rw ./tests/lib/geoip-files || true
chmod a+rw ./plugins/*/tests/System/processed || true
chmod a+rw ./plugins/*/tests/Integration/processed || true

# install phpredis
echo 'extension="redis.so"' > ./tmp/redis.ini
phpenv config-add ./tmp/redis.ini

#
# php.ini config
#

# increase memory limit
echo "memory_limit = 256M" >> ~/.phpenv/versions/$(phpenv version-name)/etc/php.ini

# enable local infile for mysqli
echo "mysqli.allow_local_infile = On" >> ~/.phpenv/versions/$(phpenv version-name)/etc/php.ini
