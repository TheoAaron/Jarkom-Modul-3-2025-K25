# Node Galadriel
cat > /etc/nginx/sites-available/galadriel << EOF
server {
    listen 8004;
    server_name galadriel.k25.com;

    root /var/www/html;
    index index.php index.html index.htm;

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
cat > /etc/nginx/sites-available/celeborn << EOF
server {
    listen 8005;
    server_name celeborn.k25.com;

    root /var/www/html;
    index index.php index.html index.htm;

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
cat > /etc/nginx/sites-available/oropher << EOF
server {
    listen 8006;
    server_name oropher.k25.com;

    root /var/www/html;
    index index.php index.html index.htm;

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
# Verifikasi PHP-FPM socket
ls -la /var/run/php/php8.4-fpm.sock
service php8.4-fpm status

# Node Client (Narv)
echo "nameserver 10.76.3.3" > /etc/resolv.conf

# Test akses via domain (sekarang PHP harus berjalan)
curl http://galadriel.k25.com:8004
# Expected: Hostname: galadriel

curl http://celeborn.k25.com:8005
# Expected: Hostname: celeborn

curl http://oropher.k25.com:8006
# Expected: Hostname: oropher

# Test dengan lynx
apt-get update
apt-get install -y lynx

lynx http://galadriel.k25.com:8004
lynx http://celeborn.k25.com:8005
lynx http://oropher.k25.com:8006