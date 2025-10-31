# Node Galadriel
# Buat user dan password (user: noldor, pass: silvan)
apt-get update
apt-get install -y apache2-utils

htpasswd -bc /etc/nginx/.htpasswd noldor silvan

cat > /etc/nginx/sites-available/galadriel << EOF
server {
    listen 8004;
    server_name galadriel.k25.com;

    root /var/www/html;
    index index.php index.html index.htm;

    # Basic Authentication
    auth_basic "Restricted Access - Realm of Galadriel";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

nginx -t
service nginx restart

# Node Celeborn
# Buat user dan password (user: noldor, pass: silvan)
apt-get update
apt-get install -y apache2-utils

htpasswd -bc /etc/nginx/.htpasswd noldor silvan

cat > /etc/nginx/sites-available/celeborn << EOF
server {
    listen 8005;
    server_name celeborn.k25.com;

    root /var/www/html;
    index index.php index.html index.htm;

    # Basic Authentication
    auth_basic "Restricted Access - Realm of Celeborn";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

nginx -t
service nginx restart

# Node Oropher
# Buat user dan password (user: noldor, pass: silvan)
apt-get update
apt-get install -y apache2-utils

htpasswd -bc /etc/nginx/.htpasswd noldor silvan

cat > /etc/nginx/sites-available/oropher << EOF
server {
    listen 8006;
    server_name oropher.k25.com;

    root /var/www/html;
    index index.php index.html index.htm;

    # Basic Authentication
    auth_basic "Restricted Access - Realm of Oropher";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

nginx -t
service nginx restart

# TEST

# Node Galadriel, Celeborn, Oropher
# Verifikasi file htpasswd
cat /etc/nginx/.htpasswd
# Expected: noldor:$apr1$...

# Node Client
echo "nameserver 10.76.3.3" > /etc/resolv.conf

# Test tanpa authentication (harus gagal - 401 Unauthorized)
curl http://galadriel.k25.com:8004
curl http://celeborn.k25.com:8005
curl http://oropher.k25.com:8006

# Test dengan authentication (harus berhasil)
curl -u noldor:silvan http://galadriel.k25.com:8004
curl -u noldor:silvan http://celeborn.k25.com:8005
curl -u noldor:silvan http://oropher.k25.com:8006

# Test dengan password salah (harus gagal - 401 Unauthorized)
curl -u noldor:wrongpass http://galadriel.k25.com:8004