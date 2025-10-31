# Node Galadriel, Celeborn, Oropher
apt-get update
apt-get install -y nginx php8.4 php8.4-fpm

# Buat directory untuk web
mkdir -p /var/www/html
chown -R www-data:www-data /var/www/html


# Node Galadriel
cat > /var/www/html/index.php <<'EOF'
<?php
echo "Hostname: " . htmlspecialchars(gethostname(), ENT_QUOTES, 'UTF-8') . "\n";
?>
EOF

cat > /etc/nginx/sites-available/galadriel <<EOF
server {
    listen 80;
    server_name galadriel.k25.com;

    root /var/www/html;
    index index.php index.html index.htm;

    # Jika request ke file fisik ada -> kirim, kalau tidak -> 404
    location / {
        try_files \$uri \$uri/ =404;
    }

    # PHP handling - penting supaya index.php diparse
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    # sembunyikan file .ht*
    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/galadriel /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t
service php8.4-fpm start
service nginx restart

# Node Celeborn
cat > /var/www/html/index.php <<'EOF'
<?php
echo "Hostname: " . htmlspecialchars(gethostname(), ENT_QUOTES, 'UTF-8') . "\n";
?>
EOF

cat > /etc/nginx/sites-available/celeborn <<EOF
server {
    listen 80;
    server_name celeborn.k25.com;

    root /var/www/html;
    index index.php index.html index.htm;

    # Jika request ke file fisik ada -> kirim, kalau tidak -> 404
    location / {
        try_files \$uri \$uri/ =404;
    }

    # PHP handling - penting supaya index.php diparse
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    # sembunyikan file .ht*
    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/celeborn /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t
service php8.4-fpm start
service nginx restart

# Node Oropher
cat > /var/www/html/index.php <<'EOF'
<?php
echo "Hostname: " . htmlspecialchars(gethostname(), ENT_QUOTES, 'UTF-8') . "\n";
?>
EOF

cat > /etc/nginx/sites-available/oropher <<EOF
server {
    listen 80;
    server_name oropher.k25.com;

    root /var/www/html;
    index index.php index.html index.htm;

    # Jika request ke file fisik ada -> kirim, kalau tidak -> 404
    location / {
        try_files \$uri \$uri/ =404;
    }

    # PHP handling - penting supaya index.php diparse
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    # sembunyikan file .ht*
    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/oropher /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t
service php8.4-fpm start
service nginx restart

# TEST

# Node Client 
echo "nameserver 10.76.3.3" > /etc/resolv.conf

# Test akses via domain (seharusnya bisa)
curl http://galadriel.k25.com
curl http://celeborn.k25.com
curl http://oropher.k25.com
