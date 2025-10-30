# Node Palantir
apt-get install -y mariadb-server

service mysql start

mysql -e "CREATE DATABASE laravel_db;"
mysql -e "CREATE USER 'laravel_user'@'%' IDENTIFIED BY 'password123';"
mysql -e "GRANT ALL PRIVILEGES ON laravel_db.* TO 'laravel_user'@'%';"
mysql -e "FLUSH PRIVILEGES;"

sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

service mysql restart

# Node Elendil, Isildur, Anarion
cd /var/www/laravel-simple-rest-api

cat > .env << EOF
APP_NAME=Laravel
APP_ENV=local
APP_KEY=base64:generated_key_here
APP_DEBUG=true
APP_URL=http://localhost

DB_CONNECTION=mysql
DB_HOST=10.76.4.3
DB_PORT=3306
DB_DATABASE=laravel_db
DB_USERNAME=laravel_user
DB_PASSWORD=password123
EOF

php artisan key:generate

# Node Elendil - Run migration
cd /var/www/laravel-simple-rest-api
php artisan migrate:fresh --seed

# Node Elendil
cat > /etc/nginx/sites-available/elendil << EOF
server {
    listen 8001;
    server_name elendil.k25.com;

    root /var/www/laravel-simple-rest-api/public;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/elendil /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

nginx -t
service nginx restart
service php8.4-fpm restart

# Node Isildur
cat > /etc/nginx/sites-available/isildur << EOF
server {
    listen 8002;
    server_name isildur.k25.com;

    root /var/www/laravel-simple-rest-api/public;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/isildur /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

nginx -t
service nginx restart
service php8.4-fpm restart

# Node Anarion
cat > /etc/nginx/sites-available/anarion << EOF
server {
    listen 8003;
    server_name anarion.k25.com;

    root /var/www/laravel-simple-rest-api/public;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/anarion /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

nginx -t
service nginx restart
service php8.4-fpm restart

# TEST

# Node Palantir
service mysql status
mysql -e "SHOW DATABASES;"
mysql -e "SELECT user, host FROM mysql.user WHERE user='laravel_user';"
mysql -u laravel_user -p laravel_db # Password: password123
cat /etc/mysql/mariadb.conf.d/50-server.cnf | grep bind-address # Expected: 0.0.0.0 (allow remote)
netstat -tulpn | grep 3306

# Node Elendil
cd /var/www/laravel-simple-rest-api
php artisan migrate:fresh --seed
mysql -h 10.76.4.3 -u laravel_user -p -e "USE laravel_db; SHOW TABLES;"
mysql -h 10.76.4.3 -u laravel_user -p -e "USE laravel_db; SELECT COUNT(*) FROM animes;"
nginx -t
netstat -tulpn | grep 8001
curl http://10.76.1.2:8001

# Node Isildur
netstat -tulpn | grep 8002
curl http://10.76.1.3:8002

# Node Anarion
netstat -tulpn | grep 8003
curl http://10.76.1.4:8003

# Node Client (Miriel)
curl http://10.76.1.2:8001 # Expected: 404 atau connection refused
curl http://elendil.k25.com:8001 # Harus berhasil