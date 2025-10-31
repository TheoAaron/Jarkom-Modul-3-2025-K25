# Node Galadriel
# Update index.php untuk menampilkan IP pengunjung
cat > /var/www/html/index.php << 'EOF'
<?php
$hostname = gethostname();
$real_ip = $_SERVER['HTTP_X_REAL_IP'] ?? $_SERVER['REMOTE_ADDR'];

echo "Hostname: $hostname\n";
echo "Client IP: $real_ip\n";
?>
EOF

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
        
        # Pass real IP to PHP
        fastcgi_param HTTP_X_REAL_IP \$remote_addr;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

nginx -t
service nginx restart

# Node Celeborn
cat > /var/www/html/index.php << 'EOF'
<?php
$hostname = gethostname();
$real_ip = $_SERVER['HTTP_X_REAL_IP'] ?? $_SERVER['REMOTE_ADDR'];

echo "Hostname: $hostname\n";
echo "Client IP: $real_ip\n";
?>
EOF

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
        
        # Pass real IP to PHP
        fastcgi_param HTTP_X_REAL_IP \$remote_addr;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

nginx -t
service nginx restart

# Node Oropher
cat > /var/www/html/index.php << 'EOF'
<?php
$hostname = gethostname();
$real_ip = $_SERVER['HTTP_X_REAL_IP'] ?? $_SERVER['REMOTE_ADDR'];

echo "Hostname: $hostname\n";
echo "Client IP: $real_ip\n";
?>
EOF

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
        
        # Pass real IP to PHP
        fastcgi_param HTTP_X_REAL_IP \$remote_addr;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

nginx -t
service nginx restart

# TEST

# Node Client 
echo "nameserver 10.76.3.3" > /etc/resolv.conf

curl -u noldor:silvan http://galadriel.k25.com:8004

curl -u noldor:silvan http://celeborn.k25.com:8005

curl -u noldor:silvan http://oropher.k25.com:8006