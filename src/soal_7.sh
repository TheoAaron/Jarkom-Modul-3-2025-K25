# Node Elendil, Isildur, Anarion (Laravel Workers)

apt-get update && apt-get install -y lsb-release ca-certificates apt-transport-https software-properties-common gnupg2
curl -sSL https://packages.sury.org/php/README.txt | bash -x
apt-get install -y php8.4 php8.4-fpm php8.4-mysql php8.4-mbstring php8.4-xml php8.4-curl php8.4-zip unzip nginx git

curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

cd /var/www
git clone https://github.com/elshiraphine/laravel-simple-rest-api.git
cd laravel-simple-rest-api

composer install
composer update

cp .env.example .env

php artisan key:generate

# TEST

# Node Elendil, Isildur, Anarion
ls -la /var/www/laravel-simple-rest-api/
cat /var/www/laravel-simple-rest-api/.env

ls /var/www/laravel-simple-rest-api/vendor/

# Test artisan
cd /var/www/laravel-simple-rest-api
php artisan --version