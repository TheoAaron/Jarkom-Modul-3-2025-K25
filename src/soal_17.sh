# Node Client
apt-get update
apt-get install -y apache2-utils

echo "nameserver 10.76.3.3" > /etc/resolv.conf

# BENCHMARK PERTAMA - Semua worker aktif
echo "==================================================="
echo "BENCHMARK 1: Semua worker aktif"
echo "==================================================="

ab -n 1000 -c 50 -A noldor:silvan http://pharazon.k25.com/

# Pastikan Galadriel Aktif
service nginx start
service nginx status

# Analisis distribusi beban
# Node Pharazon
echo "==================================================="
echo "DISTRIBUSI BEBAN - Semua worker aktif:"
echo "==================================================="
tail -1000 /var/log/nginx/pharazon_access.log
# Expected: Request terdistribusi merata ke 3 worker

# SIMULASI KEGAGALAN - Matikan Galadriel
# Node Galadriel
echo "==================================================="
echo "SIMULASI: Galadriel down"
echo "==================================================="
service nginx stop
service nginx status

# BENCHMARK KEDUA - Galadriel down
# Node Client 
echo "==================================================="
echo "BENCHMARK 2: Galadriel down (hanya 2 worker aktif)"
echo "==================================================="

ab -n 1000 -c 50 -A noldor:silvan http://pharazon.k25.com/

# Analisis distribusi beban setelah failover
# Node Pharazon
echo "==================================================="
echo "DISTRIBUSI BEBAN - Galadriel down:"
echo "==================================================="
tail -1000 /var/log/nginx/pharazon_access.log 
# Expected: Request hanya ke Celeborn & Oropher, tidak ada ke Galadriel

# RECOVERY - Hidupkan kembali Galadriel
# Node Galadriel
echo "==================================================="
echo "RECOVERY: Galadriel kembali aktif"
echo "==================================================="
service nginx start
service nginx status

# BENCHMARK KETIGA - Semua worker aktif kembali
# Node Client
echo "==================================================="
echo "BENCHMARK 3: Recovery - Semua worker aktif kembali"
echo "==================================================="

ab -n 1000 -c 50 -A noldor:silvan http://pharazon.k25.com/

# Node Pharazon
echo "==================================================="
echo "DISTRIBUSI BEBAN - Setelah recovery:"
echo "==================================================="
tail -1000 /var/log/nginx/pharazon_access.log 
# Expected: Request kembali terdistribusi merata ke 3 worker

# ANALISIS TAMBAHAN
# Node Pharazon
echo "==================================================="
echo "ANALISIS HTTP STATUS CODES:"
echo "==================================================="
tail -1000 /var/log/nginx/pharazon_access.log | awk '{print $9}' | sort | uniq -c
# Expected: Mayoritas 200 OK, beberapa 502 Bad Gateway saat Galadriel down

# Node Galadriel - Matikan lagi untuk test
service nginx stop

# Node Client - Test beberapa request
for i in {1..20}; do
    echo "Request $i:"
    curl -u noldor:silvan -s -o /dev/null -w "Status: %{http_code}\n" http://pharazon.k25.com/
    sleep 0.5
done
# Expected: Semua request berhasil (200), Pharazon otomatis skip Galadriel

# Node Galadriel - Hidupkan kembali
service nginx start