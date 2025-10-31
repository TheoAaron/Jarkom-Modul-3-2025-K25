# Node Narvi (Client) - Install apache2-utils untuk ab command
apt-get update
apt-get install -y apache2-utils htop

# Node Elendil, Isildur, Anarion - Install htop untuk monitoring
apt-get update
apt-get install -y htop

# Node Elros - Pastikan nginx sudah installed
apt-get update
apt-get install -y nginx

# Node Elros
cat > /etc/nginx/sites-available/elros << 'EOF'
upstream kesatria_numenor {
    server 10.76.1.2:8001;
    server 10.76.1.3:8002;
    server 10.76.1.4:8003;
}

server {
    listen 80;
    server_name elros.k25.com;

    location / {
        proxy_pass http://kesatria_numenor;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    access_log /var/log/nginx/elros_access.log;
    error_log /var/log/nginx/elros_error.log;
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/elros /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test konfigurasi
nginx -t

# Restart nginx
service nginx restart

# Verifikasi nginx berjalan
service nginx status
netstat -tulpn | grep :80


# Tet Client

# Node Narvi
echo "nameserver 10.76.3.3" > /etc/resolv.conf

# Test DNS resolution
nslookup elros.k25.com

# serangan awa

# Node Narvi
echo "==================================================="
echo "SERANGAN AWAL: 100 requests, 10 concurrent"
echo "==================================================="

ab -n 100 -c 10 http://elros.k25.com/

# serangan penuh

# Node Narvi
echo "==================================================="
echo "SERANGAN PENUH: 2000 requests, 100 concurrent"
echo "==================================================="

ab -n 2000 -c 100 http://elros.k25.com/

# Node Elros - Cek distribusi request
tail -200 /var/log/nginx/elros_access.log | awk '{print $12}' | sort | uniq -c

# Cek error log
tail -50 /var/log/nginx/elros_error.log


# Node Elendil, Isildur, Anarion - Monitor resource usage
htop



# tambah weight

# Node Elros - Konfigurasi dengan weight
cat > /etc/nginx/sites-available/elros << 'EOF'
upstream kesatria_numenor {
    server 10.76.1.2:8001 weight=3;
    server 10.76.1.3:8002 weight=2;
    server 10.76.1.4:8003 weight=1;
}

server {
    listen 80;
    server_name elros.k25.com;

    location / {
        proxy_pass http://kesatria_numenor;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    access_log /var/log/nginx/elros_access.log;
    error_log /var/log/nginx/elros_error.log;
}
EOF

nginx -t
service nginx restart


# test

# Node Narvi
echo "==================================================="
echo "TEST DENGAN WEIGHT (3:2:1)"
echo "==================================================="

ab -n 2000 -c 100 http://elros.k25.com/

# Node Elros - Cek distribusi BARU
tail -200 /var/log/nginx/elros_access.log | awk '{print $12}' | sort | uniq -c
