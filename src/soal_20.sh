# Node Pharazon
# Buat directory untuk cache
mkdir -p /var/cache/nginx/pharazon_cache
chown -R www-data:www-data /var/cache/nginx/pharazon_cache
chmod -R 755 /var/cache/nginx/pharazon_cache


# ===== KONFIGURASI NGINX DENGAN CACHING =====

# Node Pharazon
cat > /etc/nginx/sites-available/pharazon << 'EOF'
# Rate Limiting Zone
limit_req_zone $binary_remote_addr zone=php_limit:10m rate=10r/s;

# Proxy Cache Configuration
proxy_cache_path /var/cache/nginx/pharazon_cache 
                 levels=1:2 
                 keys_zone=pharazon_cache:10m 
                 max_size=100m 
                 inactive=60m 
                 use_temp_path=off;

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

        # Caching Configuration
        proxy_cache pharazon_cache;
        proxy_cache_valid 200 304 60m;
        proxy_cache_valid 404 10m;
        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
        proxy_cache_lock on;
        
        # Add cache status header
        add_header X-Cache-Status $upstream_cache_status;
        add_header X-Proxy-Cache $upstream_cache_status;
    }

    access_log /var/log/nginx/pharazon_access.log;
    error_log /var/log/nginx/pharazon_error.log;
}
EOF

nginx -t
service nginx restart


# ===== REQUEST PERTAMA (MISS) =====

# Node Client
echo "nameserver 10.76.3.3" > /etc/resolv.conf

echo "==================================================="
echo "TEST 1: Request pertama (Cache MISS)"
echo "==================================================="

curl -u noldor:silvan -I http://pharazon.k25.com/
# Expected Headers:
# HTTP/1.1 200 OK

curl -u noldor:silvan -v http://pharazon.k25.com/ 2>&1 | grep -i "x-cache\|x-proxy"
# Expected: X-Cache-Status: MISS atau X-Proxy-Cache: MISS


# ===== REQUEST KEDUA (HIT) =====

echo "==================================================="
echo "TEST 2: Request kedua (Cache HIT)"
echo "==================================================="

sleep 1

curl -u noldor:silvan -I http://pharazon.k25.com/
# Expected Headers:
# HTTP/1.1 200 OK
# X-Cache-Status: HIT (atau X-Proxy-Cache: HIT)
# (response dari cache, tidak ke backend)

curl -u noldor:silvan -v http://pharazon.k25.com/ 2>&1 | grep -i "x-cache\|x-proxy"
# Expected: X-Cache-Status: HIT atau X-Proxy-Cache: HIT


# ===== TEST MULTIPLE REQUESTS =====

echo "==================================================="
echo "TEST 3: Multiple requests (harusnya HIT semua)"
echo "==================================================="

for i in {1..10}; do
    echo "Request $i:"
    curl -u noldor:silvan -s -I http://pharazon.k25.com/ | grep -i "x-cache\|x-proxy\|http"
done
# Expected: Request 1 = MISS, Request 2-10 = HIT


# ===== VERIFIKASI CACHE FILES =====

# Node Pharazon
echo "==================================================="
echo "VERIFIKASI CACHE FILES:"
echo "==================================================="

ls -lah /var/cache/nginx/pharazon_cache/
du -sh /var/cache/nginx/pharazon_cache/
find /var/cache/nginx/pharazon_cache/ -type f | wc -l
# Expected: Ada file-file cache yang tersimpan


# ===== TEST BEBAN DENGAN CACHING =====

# Clear cache dulu
# Node Pharazon
rm -rf /var/cache/nginx/pharazon_cache/*
service nginx restart

# Node client - Benchmark request pertama (akan populate cache)
ab -n 100 -c 10 -A noldor:silvan http://pharazon.k25.com/

# Benchmark request kedua (harusnya lebih cepat karena dari cache)
echo "==================================================="
echo "Benchmark kedua (dari cache):"
echo "==================================================="

ab -n 1000 -c 50 -A noldor:silvan http://pharazon.k25.com/
# Expected: 
# - Requests per second LEBIH TINGGI
# - Time per request LEBIH RENDAH
# - Beban di PHP workers LEBIH RENDAH


# ===== MONITORING WORKER LOAD =====

# Node Galadriel, Celeborn, Oropher
htop

# Atau cek nginx access log
tail -f /var/log/nginx/access.log
# Expected: Saat cache HIT, tidak ada request masuk ke worker


# ===== TEST CACHE DENGAN CURL DETAIL =====

# Request pertama (MISS - lambat)
echo "Request 1 (MISS):"
curl -u noldor:silvan -s -o /dev/null -w "Status: %{http_code}\nTime: %{time_total}s\n" http://pharazon.k25.com/

# Request kedua (HIT - cepat)
echo "Request 2 (HIT):"
curl -u noldor:silvan -s -o /dev/null -w "Status: %{http_code}\nTime: %{time_total}s\n" http://pharazon.k25.com/

# Expected: Request 2 lebih cepat dari Request 1


# ===== CLEAR CACHE =====

# Node Pharazon

# Cara 1: Hapus file cache
rm -rf /var/cache/nginx/pharazon_cache/*

# Cara 2: Restart nginx
service nginx restart

# Verifikasi cache kosong
ls -la /var/cache/nginx/pharazon_cache/


# ===== TEST CACHE EXPIRY =====

# Node Client
echo "==================================================="
echo "TEST 6: Cache expiry (60 menit)"
echo "==================================================="

# Request untuk populate cache
curl -u noldor:silvan -I http://pharazon.k25.com/ | grep "X-Cache"

# Request berikutnya (harusnya HIT)
curl -u noldor:silvan -I http://pharazon.k25.com/ | grep "X-Cache"

# Tunggu > 60 menit atau clear cache manual
# Node Pharazon
rm -rf /var/cache/nginx/pharazon_cache/*

# Request lagi (harusnya MISS karena cache expired/cleared)
curl -u noldor:silvan -I http://pharazon.k25.com/ | grep "X-Cache"


# ===== ANALISIS CACHE PERFORMANCE =====

# Node Pharazon
echo "==================================================="
echo "ANALISIS CACHE HIT RATE:"
echo "==================================================="


# Calculate hit rate
TOTAL=$(tail -1000 /var/log/nginx/pharazon_access.log | wc -l)
HITS=$(tail -1000 /var/log/nginx/pharazon_access.log | grep "HIT" | wc -l)
echo "Total Requests: $TOTAL"
echo "Cache Hits: $HITS"
echo "Hit Rate: $(( HITS * 100 / TOTAL ))%"