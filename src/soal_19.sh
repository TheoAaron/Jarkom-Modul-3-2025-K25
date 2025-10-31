# Node Elros
cat > /etc/nginx/sites-available/elros << 'EOF'
# Rate Limiting Zone: 10 requests per second per IP
limit_req_zone $binary_remote_addr zone=laravel_limit:10m rate=10r/s;

upstream kesatria_numenor {
    server 10.76.1.2:8001 weight=3;
    server 10.76.1.3:8002 weight=2;
    server 10.76.1.4:8003 weight=1;
}

server {
    listen 80;
    server_name elros.k25.com;

    # Apply rate limiting
    limit_req zone=laravel_limit burst=20 nodelay;
    limit_req_status 429;

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


# ===== PART 2: RATE LIMITING - PHARAZON (PHP Load Balancer) =====


# Kalau error fie dah ada
# 1. Hapus semua symbolic link yang rusak
rm -f /etc/nginx/sites-enabled/*

# 2. Cek file yang ada di sites-available
ls -la /etc/nginx/sites-available/

# Node Pharazon
cat > /etc/nginx/sites-available/pharazon << 'EOF'
# Rate Limiting Zone: 10 requests per second per IP
limit_req_zone $binary_remote_addr zone=php_limit:10m rate=10r/s;

upstream kesatria_lorien {
    server 10.76.2.5:8004;  # Galadriel
    server 10.76.2.6:8005;  # Celeborn
    server 10.76.2.7:8006;  # Oropher
}

server {
    listen 80;
    server_name pharazon.k25.com;

    # Apply rate limiting
    limit_req zone=php_limit burst=20 nodelay;
    limit_req_status 429;

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

nginx -t
service nginx restart



# ===== TEST RATE LIMITING - ELROS =====

# Node (Client)
echo "nameserver 10.76.3.3" > /etc/resolv.conf

echo "==================================================="
echo "TEST 1: Normal request (tidak melebihi limit)"
echo "==================================================="

for i in {1..10}; do
    curl -s -o /dev/null -w "Request $i: Status %{http_code}\n" http://elros.k25.com/
    sleep 0.2  # 5 req/sec (di bawah limit 10 req/sec)
done
# Expected: Semua 200 OK

echo "==================================================="
echo "TEST 2: Burst request (melebihi limit)"
echo "==================================================="

for i in {1..30}; do
    curl -s -o /dev/null -w "Request $i: Status %{http_code}\n" http://elros.k25.com/ &
done
wait
# Expected: Beberapa 200 OK, beberapa 429 Too Many Requests

echo "==================================================="
echo "TEST 3: Apache Bench dengan konkurensi tinggi"
echo "==================================================="

ab -n 1000 -c 50 http://elros.k25.com/
# Expected: Banyak failed requests atau non-2xx responses

# Node Elros - Cek log error
tail -50 /var/log/nginx/elros_error.log | grep "limiting requests"
# Expected: Log seperti:
# [error] 1234#1234: *5678 limiting requests, excess: 20.500 by zone "laravel_limit"


# ===== PART 5: TEST RATE LIMITING - PHARAZON =====

# Node (Client)
echo "==================================================="
echo "TEST 4: Normal request Pharazon (tidak melebihi limit)"
echo "==================================================="

for i in {1..10}; do
    curl -u noldor:silvan -s -o /dev/null -w "Request $i: Status %{http_code}\n" http://pharazon.k25.com/
    sleep 0.2
done
# Expected: Semua 200 OK

echo "==================================================="
echo "TEST 5: Burst request Pharazon (melebihi limit)"
echo "==================================================="

for i in {1..30}; do
    curl -u noldor:silvan -s -o /dev/null -w "Request $i: Status %{http_code}\n" http://pharazon.k25.com/ &
done
wait
# Expected: Beberapa 200 OK, beberapa 429 Too Many Requests

echo "==================================================="
echo "TEST 6: Apache Bench Pharazon dengan konkurensi tinggi"
echo "==================================================="

ab -n 1000 -c 50 -A noldor:silvan http://pharazon.k25.com/
# Expected:
# Complete requests: 1000
# Failed requests: XXX (banyak yang ditolak)
# Non-2xx responses: XXX (429 Too Many Requests)

# Node Pharazon - Cek log error
tail -50 /var/log/nginx/pharazon_error.log | grep "limiting requests"
# Expected: Log error rate limiting

# Hitung berapa request yang ditolak (429) Elros
tail -1000 /var/log/nginx/elros_access.log | awk '{print $9}' | grep 429 | wc -l

# Lihat distribusi status code
tail -1000 /var/log/nginx/elros_access.log | awk '{print $9}' | sort | uniq -c
# Expected:
# XXX 200  (request berhasil)
# XXX 429  (request ditolak rate limit)

# Node Pharazon
echo "==================================================="
echo "ANALISIS LOG PHARAZON:"
echo "==================================================="

tail -1000 /var/log/nginx/pharazon_access.log | awk '{print $9}' | sort | uniq -c