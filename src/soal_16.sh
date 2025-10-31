# Node Pharazon
apt-get update
apt-get install -y nginx

cat > /etc/nginx/sites-available/pharazon << 'EOF'
upstream kesatria_lorien {
    server 10.76.2.5:8004;  # Galadriel
    server 10.76.2.6:8005;  # Celeborn
    server 10.76.2.7:8006;  # Oropher
}

server {
    listen 80;
    server_name pharazon.k25.com;

    location / {
        proxy_pass http://kesatria_lorien;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Forward Basic Authentication headers
        proxy_set_header Authorization $http_authorization;
        proxy_pass_header Authorization;
    }

    access_log /var/log/nginx/pharazon_access.log;
    error_log /var/log/nginx/pharazon_error.log;
}
EOF

ln -sf /etc/nginx/sites-available/pharazon /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t
service nginx restart

# TEST

# Node Pharazon
service nginx status
netstat -tulpn | grep :80
cat /etc/nginx/sites-available/pharazon | grep -A 5 upstream

# Node Client
apt-get update
apt-get install -y lynx

echo "nameserver 10.76.3.3" > /etc/resolv.conf

# Test tanpa authentication (harus gagal - 401)
curl http://pharazon.k25.com
# Expected: 401 Unauthorized

# Test dengan authentication (harus berhasil)
curl -u noldor:silvan http://pharazon.k25.com
# Expected: Hostname: galadriel/celeborn/oropher
# Expected: Client IP: <client_ip>

# Test beberapa kali untuk lihat load balancing
for i in {1..10}; do
    curl -u noldor:silvan -s http://pharazon.k25.com | grep "Hostname"
done

# Node Pharazon - Monitor log
tail -f /var/log/nginx/pharazon_access.log
