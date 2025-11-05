# Laporan Praktikum Jaringan Komputer - Modul 3

| Nama                        | NRP        |
| --------------------------- | ---------- |
| Syifa Nurul Alfiah          | 5027241019 |
| Theodorus Aaron Ugraha      | 5027241056 |

## Soal 1: Setup Semua Node (Network, Forwarding, Firewall)

### Tujuan
Menyiapkan konfigurasi jaringan dasar untuk semua node: interface IP statis/dhcp, IP forwarding di router (`Durin`), dan aturan NAT serta forwarding dengan iptables.

### Konfigurasi (ringkasan)

Beberapa langkah kunci yang dilakukan di script:

```bash
# Aktifkan IP forwarding di Durin
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.conf

# NAT untuk akses internet
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE -s 10.76.0.0/16

# Contoh aturan FORWARD antara subnet
iptables -A FORWARD -i eth1 -o eth2 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -j ACCEPT

# Interface static examples (potongan untuk Durin/Elendil/...)
auto eth1
iface eth1 inet static
    address 10.76.1.1
    netmask 255.255.255.0
```

### Testing

- Install paket utilitas: `apt-get install -y nano dnsutils lynx htop curl apache2-utils`
- Test konektivitas: `ping -c 3 8.8.8.8` dan `ping -c 3 google.com` dari node mana pun.

### Expected Output / Analisis

- IP forwarding harus aktif di Durin.
- Mesin di subnet internal dapat akses keluar melalui NAT.
- Aturan iptables memungkinkan routing antar subnet yang didefinisikan.

---

## Soal 2: DHCP Server dan Relay (Aldarion & Durin)

### Tujuan
Mengonfigurasi Aldarion sebagai DHCP server untuk beberapa subnet dan Durin sebagai DHCP relay.

### Konfigurasi

Contoh potongan `/etc/dhcp/dhcpd.conf` pada Aldarion:

```bash
subnet 10.76.1.0 netmask 255.255.255.0 {
    range 10.76.1.6 10.76.1.34;
    range 10.76.1.68 10.76.1.94;
    option routers 10.76.1.1;
    option domain-name-servers 10.76.3.3;
    default-lease-time 1800;
    max-lease-time 3600;
}

# Host fixed-address example
host Khamul {
    hardware ethernet 02:42:dc:08:82:00;
    fixed-address 10.76.3.95;
}
```

Durin sebagai relay dikonfigurasi di `/etc/default/isc-dhcp-relay`:

```text
SERVERS="10.76.4.2"
INTERFACES="eth1 eth2 eth3 eth4"
```

### Testing

- Restart service: `service isc-dhcp-server restart` (Aldarion) dan `service isc-dhcp-relay restart` (Durin).
- Client yang berada di subnet DHCP: jalankan `dhclient -v eth0` lalu cek `ip addr show eth0`.
- Verifikasi lease file: `cat /var/lib/dhcp/dhcpd.leases`.

### Expected Output / Analisis

- Client dalam range akan menerima alamat sesuai konfigurasi.
- Host dengan MAC tertentu (Khamul) akan mendapat fixed address 10.76.3.95.

---

## Soal 3: DNS Forwarder (Minastir)

### Tujuan
Menjalankan caching/forwarding DNS server (Bind9) yang mem-forward permintaan eksternal ke public resolvers.

### Konfigurasi

Potongan `named.conf.options` (Minastir):

```text
options {
    directory "/var/cache/bind";
    forwarders { 8.8.8.8; 8.8.4.4; 1.1.1.1; };
    forward only;
    allow-query { 10.76.0.0/16; localhost; };
    listen-on { any; };
    listen-on-v6 { none; };
}
```

Semua node client diarahkan ke Minastir dengan menulis `nameserver 10.76.5.2` ke `/etc/resolv.conf`.

### Testing

- Restart named: `service named restart`.
- Tes resolve: `nslookup google.com 10.76.5.2`, `dig @10.76.5.2 google.com`.

### Expected Output

- DNS query berhasil lewat forwarder; Minastir merespon untuk klien internal.

---

## Soal 4: DNS Authoritative - Master/Slave (Erendis & Amdir)

### Tujuan
Menyiapkan zone `k25.com` di Erendis sebagai master dan Amdir sebagai slave.

### Konfigurasi

Contoh zone file `/etc/bind/jarkom/k25.com` (Erendis):

```text
$TTL 604800
@ IN SOA k25.com. root.k25.com. (
    2024102801 ; Serial
    604800
    86400
    2419200
    604800 )
;
@ IN NS ns1.k25.com.
@ IN NS ns2.k25.com.
ns1 IN A 10.76.3.3
ns2 IN A 10.76.3.4
elros IN A 10.76.1.7
elendil IN A 10.76.1.2
...
```

Pada Amdir (slave) `named.conf.local` mengonfigurasi zone type slave dengan `masters { 10.76.3.3; };`.

### Testing

- Cek master: `named-checkzone k25.com /etc/bind/jarkom/k25.com`.
- Dari client: `nslookup elros.k25.com` dengan nameserver 10.76.3.3 atau 10.76.3.4.

### Expected Output

- Record k25.com dapat di-resolve dari master dan slave; transfer zona berhasil ke slave.

---

## Soal 5: Penambahan Record (CNAME, TXT) dan Reverse Zone

### Tujuan
Menambahkan CNAME `www` -> `k25.com`, beberapa TXT records, dan membuat reverse zone untuk subnet 10.76.3.0/24.

### Konfigurasi

Contoh tambahan pada zone file:

```text
www IN CNAME k25.com.
elros IN TXT "Cincin Sauron"
pharazon IN TXT "Aliansi Terakhir"

; Reverse zone /etc/bind/jarkom/3.76.10.in-addr.arpa
3 IN PTR ns1.k25.com.
4 IN PTR ns2.k25.com.
```

### Testing

- `dig @localhost www.k25.com` untuk CNAME.
- `dig @localhost elros.k25.com TXT` untuk TXT record.
- `dig -x 10.76.3.3` untuk reverse lookup.

### Expected Output

- CNAME dan TXT muncul sesuai konfigurasi; PTR untuk IP di subnet 10.76.3.0 mengembalikan nama host.

---

## Soal 6: Verifikasi Lease DHCP (Client)

### Tujuan
Memverifikasi nilai lease yang diberikan oleh DHCP server untuk dua client contoh (Amandil, Gilgalad) sesuai konfigurasi Aldarion.

### Konfigurasi & Testing

- Di client: renew DHCP `dhclient -v eth0` lalu periksa `/var/lib/dhcp/dhclient.leases`.
- Cari `lease-time`, `renew`, `rebind`, `expire` entry.

### Expected / Analisis

- Untuk subnet Manusia (10.76.1.0): default-lease-time 1800 (30 menit), max-lease-time 3600 (1 jam).
- Untuk subnet Peri (10.76.2.0): default-lease-time 600 (10 menit), max-lease-time 3600 (1 jam).

---

## Soal 7: Men-deploy Laravel Workers (Elendil, Isildur, Anarion)

### Tujuan
Menyiapkan aplikasi Laravel (simple REST API) pada tiga worker, memasang PHP, composer, dan Nginx.

### Konfigurasi (ringkasan)

Langkah utama yang dilakukan pada tiap worker:

```bash
apt-get install -y php8.4 php8.4-fpm nginx git unzip
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
cd /var/www
git clone https://github.com/elshiraphine/laravel-simple-rest-api.git
cd laravel-simple-rest-api
composer install
cp .env.example .env
php artisan key:generate
```

Nginx site dibuat masing-masing untuk listen pada port custom 8001/8002/8003 dan mengembalikan 444 untuk akses via IP.

### Testing

- Periksa `php artisan --version`, pastikan vendor terinstal.
- `nginx -t` lalu restart `service nginx restart` dan `service php8.4-fpm restart`.

### Expected Output

- Aplikasi Laravel dapat diakses via domain masing-masing (elendil.k25.com:8001, isildur.k25.com:8002, anarion.k25.com:8003) dan endpoint `/api/airing` mengembalikan JSON.

---

## Soal 8: Database MariaDB dan Koneksi Laravel (Palantir + Elendil)

### Tujuan
Menyiapkan MariaDB di Palantir sebagai database backend dan konfigurasi aplikasi Laravel untuk terhubung ke sana.

### Konfigurasi

Palantir (database):

```bash
apt-get install -y mariadb-server mariadb-client
mysql -e "CREATE DATABASE IF NOT EXISTS laravel_db;"
mysql -e "CREATE USER IF NOT EXISTS 'laravel_user'@'%' IDENTIFIED BY 'password123';"
mysql -e "GRANT ALL PRIVILEGES ON laravel_db.* TO 'laravel_user'@'%';"
sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
service mariadb restart
```

Worker (`.env` contoh di Elendil/Isildur/Anarion):

```text
DB_CONNECTION=mysql
DB_HOST=10.76.4.3
DB_PORT=3306
DB_DATABASE=laravel_db
DB_USERNAME=laravel_user
DB_PASSWORD=password123
```

Jalankan migrate di Elendil: `php artisan migrate:fresh --seed`.

### Testing

- Dari Palantir: `mysql -u laravel_user -ppassword123 -e "USE laravel_db; SHOW TABLES;"`.
- Dari Elendil: `php artisan migrate:fresh --seed` dan cek endpoint API.

### Expected Output

- Database terbuat, tabel terisi seed data, dan API mengembalikan data dari database.

---

## Soal 9: Client Tests & Verifikasi (Miriel, Celebrimbor, Gilgalad, Amandil)

### Tujuan
Melakukan uji akses dari client ke masing-masing worker dan memverifikasi konten endpoint API konsisten.

### Testing

- Set nameserver ke DNS internal: `echo "nameserver 10.76.3.3" > /etc/resolv.conf`.
- Tes masing-masing worker:

```bash
lynx http://elendil.k25.com:8001
curl http://elendil.k25.com:8001/api/airing
curl -s http://elendil.k25.com:8001/api/airing > /tmp/elendil.json
curl -s http://isildur.k25.com:8002/api/airing > /tmp/isildur.json
curl -s http://anarion.k25.com:8003/api/airing > /tmp/anarion.json
diff /tmp/elendil.json /tmp/isildur.json
diff /tmp/isildur.json /tmp/anarion.json
```

### Expected Output / Analisis

- Endpoint `/api/airing` mengembalikan JSON dari masing-masing worker; perbedaan pada konten yang bersifat dinamis (mis. id) diharapkan, namun struktur response harus konsisten.

---

## Soal 10: Load Balancer Nginx (Round-Robin sederhana)

### Tujuan
Menyiapkan Nginx di Elros sebagai load balancer round-robin sederhana untuk tiga Laravel worker tanpa bobot.

### Konfigurasi

Contoh konfigurasi `/etc/nginx/sites-available/elros`:

```bash
upstream kesatria_numenor {
    server 10.76.1.2:8001;
    server 10.76.1.3:8002;
    server 10.76.1.4:8003;
}

server {
    listen 80 default_server;
    server_name _;
    return 444;
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
```

### Testing

- Enable site and restart Nginx: `ln -s /etc/nginx/sites-available/elros /etc/nginx/sites-enabled/ && service nginx restart`.
- Dari client lakukan beberapa request ke `http://elros.k25.com/api/airing` berulang kali dan cek access log:

```bash
for i in {1..20}; do
    curl -s http://elros.k25.com/api/airing | grep -o '"id":[0-9]*' | head -1
done

tail -100 /var/log/nginx/elros_access.log | grep -o "upstream.*" | sort | uniq -c
```

### Expected Output

- Permintaan didistribusikan secara round-robin ke masing-masing worker; access log menunjukkan traffic ke `10.76.1.2:8001`, `10.76.1.3:8002`, `10.76.1.4:8003`.

---

## Soal 11: Load Balancing dengan Weighted Round Robin

### Tujuan
Mengkonfigurasi Nginx sebagai load balancer dengan algoritma weighted round robin untuk mendistribusikan beban ke tiga Laravel worker (Elendil, Isildur, Anarion) dengan bobot berbeda.

### Konfigurasi

#### Install dan Setup Nginx di Elros
```bash
apt-get update && apt-get install -y nginx
```

#### Konfigurasi Load Balancer
```bash
cat > /etc/nginx/sites-available/elros << 'EOF'
upstream kesatria_numenor {
    server 10.76.1.2:8001 weight=3;
    server 10.76.1.3:8002 weight=2;
    server 10.76.1.4:8003 weight=1;
}

server {
    listen 80 default_server;
    server_name _;
    return 444;
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
```

**Penjelasan Konfigurasi:**

**Blok `upstream kesatria_numenor`:**
- `server 10.76.1.2:8001 weight=3`: Elendil mendapat bobot 3, menerima paling banyak request (50% dari total)
- `server 10.76.1.3:8002 weight=2`: Isildur mendapat bobot 2, menerima 33% dari total request
- `server 10.76.1.4:8003 weight=1`: Anarion mendapat bobot 1, menerima 17% dari total request
- Total weight = 6, sehingga distribusi menjadi 3:2:1 atau 50%:33%:17%

**Blok `server` pertama (default_server):**
- `listen 80 default_server`: Menangkap semua request yang tidak match dengan server block lain
- `server_name _`: Wildcard untuk semua hostname
- `return 444`: Return error 444 (Connection Closed Without Response) untuk menolak akses via IP

**Blok `server` kedua (main server):**
- `listen 80`: Listen pada port 80
- `server_name elros.k25.com`: Hanya menerima request dengan hostname elros.k25.com
- `proxy_pass http://kesatria_numenor`: Meneruskan request ke upstream group
- `proxy_set_header Host $host`: Meneruskan hostname asli ke backend
- `proxy_set_header X-Real-IP $remote_addr`: Meneruskan IP klien asli
- `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for`: Menambahkan IP ke chain forwarding
- `proxy_set_header X-Forwarded-Proto $scheme`: Meneruskan protokol (http/https)

**Logging:**
- `access_log /var/log/nginx/elros_access.log`: Log semua request yang berhasil
- `error_log /var/log/nginx/elros_error.log`: Log semua error

#### Enable Site dan Restart Nginx
```bash
ln -s /etc/nginx/sites-available/elros /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

nginx -t
service nginx restart
```

**Penjelasan:**
- `ln -s`: Membuat symbolic link untuk mengaktifkan site
- `rm /etc/nginx/sites-enabled/default`: Menghapus konfigurasi default agar tidak konflik
- `nginx -t`: Test konfigurasi sebelum restart
- `service nginx restart`: Restart Nginx untuk apply perubahan

### Testing

#### Test dari Node Miriel (Klien)
```bash
echo "nameserver 10.76.3.3" > /etc/resolv.conf

# Test akses via IP (harus ditolak)
curl -o /dev/null -s -w "HTTP Status: %{http_code}\n" http://10.76.1.7

# Test akses via domain (harus berhasil)
curl -o /dev/null -s -w "HTTP Status: %{http_code}\n" http://elros.k25.com
```

**Expected Output:**
- Akses via IP: `HTTP Status: 444` (ditolak)
- Akses via domain: `HTTP Status: 200` (berhasil)

#### Test Load Distribution
```bash
for i in {1..10}; do
    curl -s http://elros.k25.com/api/airing | grep -o '"id":[0-9]*' | head -1
done
```

**Penjelasan:**
- Loop 10 kali request ke endpoint `/api/airing`
- Melihat distribusi request ke worker berbeda

#### Monitoring Distribusi
```bash
# Di Node Elros
tail -100 /var/log/nginx/elros_access.log | grep -o "upstream.*" | sort | uniq -c
```

**Expected Output:**
```
     50 upstream: 10.76.1.2:8001
     33 upstream: 10.76.1.3:8002
     17 upstream: 10.76.1.4:8003
```

**Analisis:** Distribusi sesuai dengan weight 3:2:1

---

## Soal 12: Web Server PHP dengan Nginx dan PHP-FPM

### Tujuan
Mengkonfigurasi tiga web server (Galadriel, Celeborn, Oropher) dengan Nginx + PHP-FPM untuk melayani aplikasi PHP yang menampilkan hostname server.

### Konfigurasi

#### Install Dependencies
```bash
apt-get update
apt-get install -y nginx php8.4 php8.4-fpm

mkdir -p /var/www/html
chown -R www-data:www-data /var/www/html
```

**Penjelasan:**
- `php8.4`: PHP interpreter
- `php8.4-fpm`: FastCGI Process Manager untuk PHP
- `mkdir -p /var/www/html`: Buat directory web root
- `chown -R www-data:www-data`: Set ownership ke user nginx

#### Buat File PHP di Node Galadriel
```bash
cat > /var/www/html/index.php <<'EOF'
<?php
echo "Hostname: " . htmlspecialchars(gethostname(), ENT_QUOTES, 'UTF-8') . "\n";
?>
EOF
```

**Penjelasan Kode PHP:**
- `gethostname()`: Mendapatkan hostname sistem
- `htmlspecialchars()`: Escape HTML entities untuk keamanan
- `ENT_QUOTES, 'UTF-8'`: Flag encoding untuk mencegah XSS

#### Konfigurasi Nginx di Node Galadriel
```bash
cat > /etc/nginx/sites-available/galadriel <<EOF
server {
    listen 80 default_server;
    server_name _;
    return 444;
}

server {
    listen 80;
    server_name galadriel.k25.com;

    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
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
```

**Penjelasan Konfigurasi:**

**Blok `server` pertama:**
- `listen 80 default_server`: Default server untuk request tanpa hostname match
- `return 444`: Tolak akses via IP address

**Blok `server` kedua:**
- `server_name galadriel.k25.com`: Hanya accept request dari hostname ini
- `root /var/www/html`: Document root directory
- `index index.php`: Prioritas file index

**Location `/`:**
- `try_files $uri $uri/ =404`: Cari file fisik, jika tidak ada return 404

**Location `~ \.php$`:**
- `~ \.php$`: Regex match untuk file berakhiran .php
- `include snippets/fastcgi-php.conf`: Load konfigurasi FastCGI default
- `fastcgi_pass unix:/var/run/php/php8.4-fpm.sock`: Pass request ke PHP-FPM via Unix socket
- `fastcgi_param SCRIPT_FILENAME`: Set path file PHP yang akan dieksekusi
- `include fastcgi_params`: Load parameter FastCGI standar

**Location `~ /\.ht`:**
- `deny all`: Block akses ke file .htaccess dan .htpasswd

#### Enable Site dan Restart Services
```bash
ln -s /etc/nginx/sites-available/galadriel /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t
service php8.4-fpm start
service nginx restart
```

#### Konfigurasi Celeborn dan Oropher
Konfigurasi sama seperti Galadriel, hanya ganti `server_name`:
- Celeborn: `server_name celeborn.k25.com;`
- Oropher: `server_name oropher.k25.com;`

### Testing

#### Test dari Node Client
```bash
echo "nameserver 10.76.3.3" > /etc/resolv.conf

# Test akses via IP (harus ditolak)
curl -o /dev/null -s -w "HTTP Status: %{http_code}\n" http://10.76.2.5

# Test akses via domain (harus berhasil)
curl http://galadriel.k25.com
```

**Expected Output:**
```
HTTP Status: 444
Hostname: galadriel
```

#### Test Semua Worker
```bash
curl http://galadriel.k25.com
curl http://celeborn.k25.com
curl http://oropher.k25.com
```

**Expected Output:**
```
Hostname: galadriel
Hostname: celeborn
Hostname: oropher
```

---

## Soal 13: Custom Port untuk PHP Workers

### Tujuan
Mengubah port listening PHP workers dari port 80 ke port custom (8004, 8005, 8006) untuk isolasi service.

### Konfigurasi

#### Update Port di Node Galadriel
```bash
cat > /etc/nginx/sites-available/galadriel << EOF
server {
    listen 8004 default_server;
    server_name _;
    return 444;
}

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
```

**Penjelasan Perubahan:**
- `listen 8004`: Ganti dari port 80 ke port 8004
- `listen 8004 default_server`: Default server juga menggunakan port 8004
- Semua konfigurasi lain tetap sama

#### Update Port di Node Celeborn
```bash
cat > /etc/nginx/sites-available/celeborn << EOF
server {
    listen 8005 default_server;
    server_name _;
    return 444;
}

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
```

#### Update Port di Node Oropher
```bash
cat > /etc/nginx/sites-available/oropher << EOF
server {
    listen 8006 default_server;
    server_name _;
    return 444;
}

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
```

### Testing

#### Verifikasi PHP-FPM Socket
```bash
ls -la /var/run/php/php8.4-fpm.sock
service php8.4-fpm status
```

**Expected Output:**
```
srw-rw---- 1 www-data www-data 0 Oct 21 10:00 /var/run/php/php8.4-fpm.sock
● php8.4-fpm.service - The PHP 8.4 FastCGI Process Manager
   Active: active (running)
```

#### Test dari Node Client (Narvi)
```bash
# Test akses via IP (harus ditolak)
curl -o /dev/null -s -w "HTTP Status: %{http_code}\n" http://10.76.2.5:8004

# Test akses via domain (harus berhasil)
curl http://galadriel.k25.com:8004
```

**Expected Output:**
```
HTTP Status: 444
Hostname: galadriel
```

#### Test Semua Custom Port
```bash
curl http://galadriel.k25.com:8004
curl http://celeborn.k25.com:8005
curl http://oropher.k25.com:8006
```

**Expected Output:**
```
Hostname: galadriel
Hostname: celeborn
Hostname: oropher
```

---

## Soal 14: Basic Authentication

### Tujuan
Mengimplementasikan HTTP Basic Authentication untuk membatasi akses ke PHP workers menggunakan username dan password.

### Konfigurasi

#### Install Apache2-utils
```bash
apt-get update
apt-get install -y apache2-utils
```

**Penjelasan:**
- `apache2-utils`: Package yang berisi tool `htpasswd` untuk membuat password file

#### Buat Password File di Node Galadriel
```bash
htpasswd -bc /etc/nginx/.htpasswd noldor silvan
```

**Penjelasan Perintah:**
- `htpasswd`: Tool untuk create/update password file
- `-b`: Batch mode (password dari command line, bukan prompt)
- `-c`: Create new file (gunakan hanya sekali, untuk update hapus flag -c)
- `/etc/nginx/.htpasswd`: Path file password
- `noldor`: Username
- `silvan`: Password (plaintext, akan di-hash oleh htpasswd)

**Format File `.htpasswd`:**
```
noldor:$apr1$rND8cZvh$K/jN8qXJdEOqZqJGQVJh81
```
Password di-hash menggunakan Apache MD5 algorithm.

#### Update Konfigurasi Nginx di Node Galadriel
```bash
cat > /etc/nginx/sites-available/galadriel << EOF
server {
    listen 8004 default_server;
    server_name _;
    return 444;
}

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
```

**Penjelasan Directive Authentication:**
- `auth_basic "Restricted Access - Realm of Galadriel"`: Mengaktifkan Basic Auth dengan realm message
- `auth_basic_user_file /etc/nginx/.htpasswd`: Path ke file yang berisi username:password hash

**Cara Kerja Basic Authentication:**
1. Client kirim request tanpa credentials
2. Server response HTTP 401 dengan header `WWW-Authenticate: Basic realm="..."`
3. Browser/curl prompt untuk username dan password
4. Client kirim request ulang dengan header `Authorization: Basic base64(username:password)`
5. Nginx decode dan cek di `.htpasswd` file
6. Jika match, allow access; jika tidak, return 401

#### Konfigurasi Celeborn dan Oropher
Sama seperti Galadriel, tambahkan directive:
```nginx
auth_basic "Restricted Access - Realm of Celeborn";
auth_basic_user_file /etc/nginx/.htpasswd;
```

Dan buat password file yang sama:
```bash
htpasswd -bc /etc/nginx/.htpasswd noldor silvan
```

### Testing

#### Verifikasi Password File
```bash
cat /etc/nginx/.htpasswd
```

**Expected Output:**
```
noldor:$apr1$...
```

#### Test Tanpa Kredensial (Harus Gagal)
```bash
curl -o /dev/null -s -w "HTTP Status: %{http_code}\n" http://galadriel.k25.com:8004
```

**Expected Output:**
```
HTTP Status: 401
```

#### Test dengan Kredensial Salah (Harus Gagal)
```bash
curl -o /dev/null -s -w "HTTP Status: %{http_code}\n" -u noldor:wrongpass http://galadriel.k25.com:8004
```

**Expected Output:**
```
HTTP Status: 401
```

#### Test dengan Kredensial Benar (Harus Berhasil)
```bash
curl -u noldor:silvan http://galadriel.k25.com:8004
```

**Penjelasan Parameter Curl:**
- `-u noldor:silvan`: Set username dan password untuk Basic Auth
- Curl otomatis encode ke Base64 dan set header Authorization

**Expected Output:**
```
Hostname: galadriel
```

#### Test Semua Worker
```bash
curl -u noldor:silvan http://galadriel.k25.com:8004
curl -u noldor:silvan http://celeborn.k25.com:8005
curl -u noldor:silvan http://oropher.k25.com:8006
```

---

## Soal 15: Logging IP Klien Asli

### Tujuan
Memodifikasi PHP workers untuk menampilkan dan log IP address klien yang sebenarnya (bukan IP load balancer) menggunakan header X-Real-IP.

### Konfigurasi

#### Update PHP di Node Galadriel
```bash
cat > /var/www/html/index.php << 'EOF'
<?php
$hostname = gethostname();
$real_ip = $_SERVER['HTTP_X_REAL_IP'] ?? $_SERVER['REMOTE_ADDR'];

echo "Hostname: $hostname\n";
echo "Client IP: $real_ip\n";
?>
EOF
```

**Penjelasan Kode PHP:**
- `$_SERVER['HTTP_X_REAL_IP']`: Header X-Real-IP yang dikirim load balancer
- `?? $_SERVER['REMOTE_ADDR']`: Fallback ke REMOTE_ADDR jika header tidak ada (null coalescing operator)
- `REMOTE_ADDR`: IP address dari koneksi TCP (akan menunjukkan IP load balancer jika melalui proxy)

#### Update Konfigurasi Nginx di Node Galadriel
```bash
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
```

**Penjelasan Directive Baru:**
- `fastcgi_param HTTP_X_REAL_IP $remote_addr`: Set FastCGI parameter yang akan menjadi `$_SERVER['HTTP_X_REAL_IP']` di PHP
- `$remote_addr`: Variable Nginx yang berisi IP address dari koneksi TCP langsung

**Catatan Penting:**
- Jika akses langsung ke worker: `$remote_addr` = IP klien asli
- Jika akses via load balancer: `$remote_addr` = IP load balancer
- Header `X-Real-IP` dari load balancer harus di-pass ke PHP

#### Konfigurasi Celeborn dan Oropher
Sama seperti Galadriel, update PHP dan Nginx dengan konfigurasi yang sama.

### Testing

#### Test dari Node Client
```bash
echo "nameserver 10.76.3.3" > /etc/resolv.conf

curl -u noldor:silvan http://galadriel.k25.com:8004
```

**Expected Output:**
```
Hostname: galadriel
Client IP: 10.76.4.4  (IP klien yang mengakses)
```

#### Test Melalui Load Balancer Pharazon
```bash
curl -u noldor:silvan http://pharazon.k25.com
```

**Expected Output:**
```
Hostname: galadriel (atau celeborn/oropher)
Client IP: 10.76.4.4  (IP klien asli, bukan IP Pharazon)
```

**Analisis:**
- Tanpa konfigurasi X-Real-IP: akan tampil IP load balancer
- Dengan konfigurasi X-Real-IP: akan tampil IP klien asli

---

## Soal 16: Load Balancer untuk PHP Workers

### Tujuan
Membuat load balancer Pharazon yang mendistribusikan request ke tiga PHP workers (Galadriel, Celeborn, Oropher) dengan meneruskan authentication headers.

### Konfigurasi

#### Install Nginx di Node Pharazon
```bash
apt-get update
apt-get install -y nginx
```

#### Konfigurasi Load Balancer di Pharazon
```bash
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
```

**Penjelasan Konfigurasi:**

**Blok `upstream kesatria_lorien`:**
- `server 10.76.2.5:8004`: Backend Galadriel
- `server 10.76.2.6:8005`: Backend Celeborn
- `server 10.76.2.7:8006`: Backend Oropher
- Tidak ada weight, jadi round-robin standard (1:1:1)

**Proxy Headers:**
- `proxy_set_header Host $host`: Meneruskan hostname original
- `proxy_set_header X-Real-IP $remote_addr`: Meneruskan IP klien asli
- `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for`: Chain IP forwarding
- `proxy_set_header X-Forwarded-Proto $scheme`: Meneruskan protokol (http/https)

**Authentication Headers (PENTING):**
- `proxy_set_header Authorization $http_authorization`: Meneruskan header Authorization dari klien
- `proxy_pass_header Authorization`: Memastikan response Authorization header juga diteruskan
- `$http_authorization`: Variable Nginx yang berisi header Authorization dari request

**Alur Basic Auth melalui Load Balancer:**
1. Client → Pharazon: Request dengan header `Authorization: Basic xxx`
2. Pharazon → Worker: Forward header ke backend
3. Worker: Validasi credentials di `.htpasswd`
4. Worker → Pharazon: Response (200 OK atau 401 Unauthorized)
5. Pharazon → Client: Forward response

#### Enable Site dan Restart
```bash
ln -sf /etc/nginx/sites-available/pharazon /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t
service nginx restart
```

### Testing

#### Test Status Service
```bash
service nginx status
netstat -tulpn | grep :80
```

**Expected Output:**
```
● nginx.service - A high performance web server
   Active: active (running)

tcp  0  0 0.0.0.0:80  0.0.0.0:*  LISTEN  1234/nginx
```

#### Test Tanpa Authentication (Harus Gagal)
```bash
curl http://pharazon.k25.com
```

**Expected Output:**
```
<html>
<head><title>401 Authorization Required</title></head>
<body>
<center><h1>401 Authorization Required</h1></center>
<hr><center>nginx</center>
</body>
</html>
```

#### Test dengan Authentication (Harus Berhasil)
```bash
curl -u noldor:silvan http://pharazon.k25.com
```

**Expected Output:**
```
Hostname: galadriel (atau celeborn/oropher)
Client IP: 10.76.4.4
```

#### Test Load Balancing Distribution
```bash
for i in {1..10}; do
    curl -u noldor:silvan -s http://pharazon.k25.com | grep "Hostname"
done
```

**Expected Output:**
```
Hostname: galadriel
Hostname: celeborn
Hostname: oropher
Hostname: galadriel
Hostname: celeborn
Hostname: oropher
...
```

**Analisis:** Distribusi round-robin merata ke 3 worker

#### Monitoring Log
```bash
tail -f /var/log/nginx/pharazon_access.log
```

**Format Log:**
```
10.76.4.4 - - [21/Oct/2025:10:30:00 +0000] "GET / HTTP/1.1" 200 45 "-" "curl/7.68.0"
```

---

## Soal 17: High Availability Testing dengan Failover

### Tujuan
Menguji kemampuan load balancer menangani kegagalan worker (failover) dengan simulasi mematikan salah satu backend server.

### Testing

#### Benchmark Pertama - Semua Worker Aktif
```bash
# Node Client
apt-get update
apt-get install -y apache2-utils

echo "nameserver 10.76.3.3" > /etc/resolv.conf

echo "==================================================="
echo "BENCHMARK 1: Semua worker aktif"
echo "==================================================="

ab -n 1000 -c 50 -A noldor:silvan http://pharazon.k25.com/
```

**Penjelasan Parameter ApacheBench:**
- `ab`: Apache Benchmark tool
- `-n 1000`: Total 1000 requests
- `-c 50`: Concurrency level 50 (50 request bersamaan)
- `-A noldor:silvan`: Basic Authentication credentials

**Expected Output:**
```
Concurrency Level:      50
Time taken for tests:   10.234 seconds
Complete requests:      1000
Failed requests:        0
Total transferred:      265000 bytes
Requests per second:    97.71 [#/sec] (mean)
Time per request:       511.717 [ms] (mean)
```

#### Analisis Distribusi Beban
```bash
# Node Pharazon
tail -1000 /var/log/nginx/pharazon_access.log | awk '{print $12}' | sort | uniq -c
```

**Expected Output:**
```
    333 10.76.2.5:8004
    333 10.76.2.6:8005
    334 10.76.2.7:8006
```

**Analisis:** Request terdistribusi merata ke 3 worker (sekitar 33% masing-masing)

#### Simulasi Kegagalan - Matikan Galadriel
```bash
# Node Galadriel
echo "==================================================="
echo "SIMULASI: Galadriel down"
echo "==================================================="
service nginx stop
service nginx status
```

**Expected Output:**
```
● nginx.service - A high performance web server
   Active: inactive (dead)
```

#### Benchmark Kedua - Galadriel Down
```bash
# Node Client
echo "==================================================="
echo "BENCHMARK 2: Galadriel down (hanya 2 worker aktif)"
echo "==================================================="

ab -n 1000 -c 50 -A noldor:silvan http://pharazon.k25.com/
```

**Expected Output:**
```
Concurrency Level:      50
Time taken for tests:   15.456 seconds
Complete requests:      1000
Failed requests:        167  (beberapa request gagal saat mencoba ke Galadriel)
Non-2xx responses:      167
Requests per second:    64.70 [#/sec] (mean)
```

**Analisis:**
- Time taken meningkat karena hanya 2 worker
- Failed requests muncul saat load balancer mencoba routing ke Galadriel yang down
- Nginx butuh waktu untuk mendeteksi Galadriel down (default timeout)

#### Analisis Distribusi Setelah Failover
```bash
# Node Pharazon
tail -1000 /var/log/nginx/pharazon_access.log | awk '{print $12}' | sort | uniq -c
```

**Expected Output:**
```
    500 10.76.2.6:8005
    500 10.76.2.7:8006
```

**Analisis:** Request hanya ke Celeborn dan Oropher, Galadriel tidak menerima traffic

#### Recovery - Hidupkan Kembali Galadriel
```bash
# Node Galadriel
echo "==================================================="
echo "RECOVERY: Galadriel kembali aktif"
echo "==================================================="
service nginx start
service nginx status
```

**Expected Output:**
```
● nginx.service - A high performance web server
   Active: active (running)
```

#### Benchmark Ketiga - Setelah Recovery
```bash
# Node Client
echo "==================================================="
echo "BENCHMARK 3: Recovery - Semua worker aktif kembali"
echo "==================================================="

ab -n 1000 -c 50 -A noldor:silvan http://pharazon.k25.com/
```

**Expected Output:**
```
Concurrency Level:      50
Time taken for tests:   10.456 seconds
Complete requests:      1000
Failed requests:        0
Requests per second:    95.64 [#/sec] (mean)
```

**Analisis:** Performance kembali normal seperti benchmark pertama

#### Analisis HTTP Status Codes
```bash
# Node Pharazon
tail -1000 /var/log/nginx/pharazon_access.log | awk '{print $9}' | sort | uniq -c
```

**Expected Output:**
```
    833 200  (OK)
    167 502  (Bad Gateway - saat Galadriel down)
```

**Penjelasan Status Code:**
- `200 OK`: Request berhasil diproses worker
- `502 Bad Gateway`: Load balancer tidak bisa connect ke backend (Galadriel down)

#### Test Manual Failover Behavior
```bash
# Node Galadriel - Matikan lagi
service nginx stop

# Node Client - Test beberapa request
for i in {1..20}; do
    echo "Request $i:"
    curl -u noldor:silvan -s -o /dev/null -w "Status: %{http_code}\n" http://pharazon.k25.com/
    sleep 0.5
done
```

**Expected Output:**
```
Request 1: Status: 502  (Galadriel masih di pool)
Request 2: Status: 200  (Route ke Celeborn)
Request 3: Status: 200  (Route ke Oropher)
Request 4: Status: 502  (Coba Galadriel lagi)
Request 5: Status: 200
...
```

**Analisis Failover Behavior:**
- Nginx terus mencoba Galadriel sesuai round-robin
- Setelah timeout, Nginx temporary mark Galadriel sebagai down
- Request berikutnya hanya ke Celeborn dan Oropher
- Nginx periodic check apakah Galadriel sudah up

---

## Soal 18: Database Master-Slave Replication

### Tujuan
Mengimplementasikan replikasi database MySQL/MariaDB dengan Palantir sebagai Master dan Narvi sebagai Slave untuk high availability dan load distribution.

### Konfigurasi Master (Palantir)

#### Install MariaDB
```bash
apt-get update
apt-get install -y mariadb-server
```

#### Backup Konfigurasi Original
```bash
cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.bak
```

#### Konfigurasi Master
```bash
cat >> /etc/mysql/mariadb.conf.d/50-server.cnf << EOF

# Replication Configuration - MASTER
server-id = 1
log_bin = /var/log/mysql/mysql-bin.log
binlog_do_db = laravel_db
bind-address = 0.0.0.0
EOF
```

**Penjelasan Konfigurasi Master:**
- `server-id = 1`: Unique ID untuk server dalam cluster (Master = 1)
- `log_bin = /var/log/mysql/mysql-bin.log`: Mengaktifkan binary logging untuk replikasi
- `binlog_do_db = laravel_db`: Hanya log perubahan database laravel_db (opsional, untuk efisiensi)
- `bind-address = 0.0.0.0`: Listen pada semua interface (default 127.0.0.1 hanya localhost)

**Binary Log:**
- File yang merekam semua perubahan data (INSERT, UPDATE, DELETE)
- Format: mysql-bin.000001, mysql-bin.000002, dst
- Slave membaca binary log ini untuk replikasi

#### Buat Directory Log dan Restart
```bash
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql
chmod 750 /var/log/mysql

service mariadb restart
```

**Penjelasan:**
- Directory `/var/log/mysql` untuk binary log files
- Owner `mysql:mysql` agar MariaDB bisa write
- Permission `750` (rwxr-x---) untuk security

#### Buat User Replikasi
```bash
mysql << EOF
CREATE USER 'replication_user'@'%' IDENTIFIED BY 'replication_password';
GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%';
FLUSH PRIVILEGES;
FLUSH TABLES WITH READ LOCK;
EOF
```

**Penjelasan SQL Commands:**
- `CREATE USER 'replication_user'@'%'`: Buat user yang bisa connect dari host manapun (%)
- `IDENTIFIED BY 'replication_password'`: Set password
- `GRANT REPLICATION SLAVE ON *.*`: Berikan privilege untuk replikasi
- `FLUSH PRIVILEGES`: Reload grant tables
- `FLUSH TABLES WITH READ LOCK`: Lock semua tabel untuk konsistensi saat initial snapshot

#### Catat Master Status
```bash
mysql -e "SHOW MASTER STATUS;"
```

**Expected Output:**
```
+------------------+----------+--------------+------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB |
+------------------+----------+--------------+------------------+
| mysql-bin.000001 |      328 | laravel_db   |                  |
+------------------+----------+--------------+------------------+
```

**PENTING:** Catat `File` dan `Position` untuk konfigurasi slave!

**Penjelasan Output:**
- `File`: Binary log file yang sedang aktif
- `Position`: Byte offset di file tersebut
- Slave akan mulai membaca dari posisi ini

#### Export Database
```bash
mysqldump -u root laravel_db > /tmp/laravel_db.sql
```

**Penjelasan:**
- `mysqldump`: Tool untuk export database
- `-u root`: User MySQL
- `laravel_db`: Nama database
- `> /tmp/laravel_db.sql`: Output ke file SQL

#### Unlock Tables
```bash
mysql -e "UNLOCK TABLES;"
```

**Penjelasan:** Release lock agar Master bisa menerima write operations lagi

### Konfigurasi Slave (Narvi)

#### Install MariaDB
```bash
apt-get update
apt-get install -y mariadb-server
```

#### Konfigurasi Slave
```bash
cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.bak

cat >> /etc/mysql/mariadb.conf.d/50-server.cnf << EOF

# Replication Configuration - SLAVE
server-id = 2
relay-log = /var/log/mysql/mysql-relay-bin.log
log_bin = /var/log/mysql/mysql-bin.log
binlog_do_db = laravel_db
bind-address = 0.0.0.0
EOF
```

**Penjelasan Konfigurasi Slave:**
- `server-id = 2`: Unique ID berbeda dari Master
- `relay-log = /var/log/mysql/mysql-relay-bin.log`: Log untuk menyimpan data dari Master sebelum di-apply
- `log_bin`: Slave juga bisa jadi Master untuk slave lain (optional)
- `bind-address = 0.0.0.0`: Allow connections dari network

**Relay Log:**
- Slave download binary log dari Master ke relay log
- SQL thread membaca relay log dan execute perubahan
- Format: mysql-relay-bin.000001, dst

#### Setup Directory dan Restart
```bash
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql
chmod 750 /var/log/mysql

service mariadb restart
```

#### Import Initial Data
```bash
mysql -e "CREATE DATABASE IF NOT EXISTS laravel_db;"
mysql laravel_db < /tmp/laravel_db.sql
```

**Penjelasan:**
- Buat database laravel_db
- Import dump dari Master untuk initial data
- Setelah ini, replikasi akan handle perubahan incremental

#### Konfigurasi Slave Connection
```bash
mysql << EOF
STOP SLAVE;

CHANGE MASTER TO
    MASTER_HOST='10.76.4.3',
    MASTER_USER='replication_user',
    MASTER_PASSWORD='replication_password',
    MASTER_LOG_FILE='mysql-bin.000001',
    MASTER_LOG_POS=328;

START SLAVE;
EOF
```

**Penjelasan SQL Commands:**
- `STOP SLAVE`: Stop replikasi jika sudah running
- `CHANGE MASTER TO`: Set parameter koneksi ke Master
  - `MASTER_HOST='10.76.4.3'`: IP address Palantir (Master)
  - `MASTER_USER='replication_user'`: User yang dibuat di Master
  - `MASTER_PASSWORD='replication_password'`: Password user
  - `MASTER_LOG_FILE='mysql-bin.000001'`: Binary log file dari SHOW MASTER STATUS
  - `MASTER_LOG_POS=328`: Position dari SHOW MASTER STATUS
- `START SLAVE`: Mulai replikasi

**GANTI mysql-bin.000001 dan 328 dengan nilai dari SHOW MASTER STATUS di Palantir!**

#### Cek Status Slave
```bash
mysql -e "SHOW SLAVE STATUS\G"
```

**Expected Output (hanya bagian penting):**
```
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
          Seconds_Behind_Master: 0
                   Last_Error: 
```

**Penjelasan Status:**
- `Slave_IO_Running: Yes`: IO thread berhasil connect ke Master dan download binary log
- `Slave_SQL_Running: Yes`: SQL thread berhasil execute perubahan dari relay log
- `Seconds_Behind_Master: 0`: Slave sinkron dengan Master (tidak ada delay)
- `Last_Error`: Kosong berarti tidak ada error

**Jika Slave_IO_Running atau Slave_SQL_Running = No:**
- Cek `Last_Error` untuk detail error
- Verify MASTER_HOST, MASTER_USER, MASTER_PASSWORD
- Verify firewall tidak block port 3306
- Verify Master binary log file dan position

### Testing Replikasi

#### Test 1: Buat Tabel di Master
```bash
# Node Palantir (Master)
echo "==================================================="
echo "TEST 1: Buat tabel baru di Master"
echo "==================================================="

mysql laravel_db << EOF
CREATE TABLE test_replication (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO test_replication (message) VALUES ('Data from Master Palantir');
INSERT INTO test_replication (message) VALUES ('Test replication to Narvi');
EOF

mysql -e "USE laravel_db; SELECT * FROM test_replication;"
```

**Expected Output di Master:**
```
+----+-------------------------------+---------------------+
| id | message                       | created_at          |
+----+-------------------------------+---------------------+
|  1 | Data from Master Palantir     | 2025-10-21 10:30:00 |
|  2 | Test replication to Narvi     | 2025-10-21 10:30:00 |
+----+-------------------------------+---------------------+
```

#### Verifikasi di Slave
```bash
# Node Narvi (Slave)
echo "==================================================="
echo "TEST 1: Verifikasi tabel di Slave"
echo "==================================================="

sleep 3  # Tunggu replikasi

mysql -e "USE laravel_db; SHOW TABLES;"
mysql -e "USE laravel_db; SELECT * FROM test_replication;"
```

**Expected Output di Slave:**
```
+----------------------+
| Tables_in_laravel_db |
+----------------------+
| test_replication     |
+----------------------+

+----+-------------------------------+---------------------+
| id | message                       | created_at          |
+----+-------------------------------+---------------------+
|  1 | Data from Master Palantir     | 2025-10-21 10:30:00 |
|  2 | Test replication to Narvi     | 2025-10-21 10:30:00 |
+----+-------------------------------+---------------------+
```

**Analisis:** Tabel dan data yang dibuat di Master otomatis ter-replika ke Slave

#### Test 2: Insert Data Baru di Master
```bash
# Node Palantir (Master)
echo "==================================================="
echo "TEST 2: Insert data baru di Master"
echo "==================================================="

mysql laravel_db << EOF
INSERT INTO test_replication (message) VALUES ('Additional data 1');
INSERT INTO test_replication (message) VALUES ('Additional data 2');
INSERT INTO test_replication (message) VALUES ('Additional data 3');
EOF

mysql -e "USE laravel_db; SELECT COUNT(*) as total FROM test_replication;"
```

**Expected Output:**
```
+-------+
| total |
+-------+
|     5 |
+-------+
```

#### Verifikasi di Slave
```bash
# Node Narvi (Slave)
echo "==================================================="
echo "TEST 2: Verifikasi insert di Slave"
echo "==================================================="

sleep 3

mysql -e "USE laravel_db; SELECT COUNT(*) as total FROM test_replication;"
mysql -e "USE laravel_db; SELECT * FROM test_replication ORDER BY id DESC LIMIT 3;"
```

**Expected Output:**
```
+-------+
| total |
+-------+
|     5 |
+-------+

+----+-------------------+---------------------+
| id | message           | created_at          |
+----+-------------------+---------------------+
|  5 | Additional data 3 | 2025-10-21 10:31:00 |
|  4 | Additional data 2 | 2025-10-21 10:31:00 |
|  3 | Additional data 1 | 2025-10-21 10:31:00 |
+----+-------------------+---------------------+
```

#### Test 3: Update Data di Master
```bash
# Node Palantir (Master)
mysql laravel_db << EOF
UPDATE test_replication SET message = 'Updated from Master' WHERE id = 1;
EOF

mysql -e "USE laravel_db; SELECT * FROM test_replication WHERE id = 1;"
```

#### Verifikasi di Slave
```bash
# Node Narvi (Slave)
sleep 3
mysql -e "USE laravel_db; SELECT * FROM test_replication WHERE id = 1;"
```

**Expected:** Data di Slave juga ter-update

### Monitoring Replikasi

#### Cek Status Detail di Slave
```bash
mysql -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master|Last_Error"
```

**Expected Output:**
```
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
Seconds_Behind_Master: 0
Last_Error: 
```

#### Cek Master Status
```bash
# Node Palantir
mysql -e "SHOW MASTER STATUS;"
mysql -e "SHOW PROCESSLIST;" | grep "Binlog Dump"
```

**Expected Output:**
```
+------------------+----------+--------------+------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB |
+------------------+----------+--------------+------------------+
| mysql-bin.000001 |     1250 | laravel_db   |                  |
+------------------+----------+--------------+------------------+

| Binlog Dump | laravel_db | Query  | Binlog Dump
```

**Penjelasan:**
- Position bertambah setiap ada perubahan data
- Process "Binlog Dump" menunjukkan ada Slave yang connected

---

## Soal 19: Rate Limiting

### Tujuan
Mengimplementasikan rate limiting pada load balancer untuk mencegah abuse dan melindungi backend dari overload dengan membatasi jumlah request per IP address.

### Konfigurasi Rate Limiting di Elros

#### Update Konfigurasi Nginx
```bash
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
```

**Penjelasan Directive Rate Limiting:**

**`limit_req_zone $binary_remote_addr zone=laravel_limit:10m rate=10r/s;`:**
- `$binary_remote_addr`: Key untuk tracking (IP address dalam format binary, lebih efisien dari `$remote_addr`)
- `zone=laravel_limit:10m`: Nama zone dan alokasi memory 10MB (sekitar 160,000 IP addresses)
- `rate=10r/s`: Rate limit 10 requests per second per IP

**`limit_req zone=laravel_limit burst=20 nodelay;`:**
- `zone=laravel_limit`: Gunakan zone yang sudah didefinisikan
- `burst=20`: Allow burst hingga 20 requests (buffer untuk traffic spike)
- `nodelay`: Process request burst immediately tanpa delay (alternatif: delay untuk smooth out burst)

**Cara Kerja Burst:**
- Steady rate: 10 req/sec
- Burst capacity: 20 additional requests
- Total capacity: 30 requests dalam burst window
- Setelah burst penuh, request ditolak dengan 429

**`limit_req_status 429;`:**
- Custom HTTP status code untuk rate limit exceeded
- Default 503, kita ubah ke 429 (Too Many Requests) yang lebih semantic

**Algoritma Leaky Bucket:**
- Request masuk ke "bucket" dengan rate tertentu
- Bucket process request dengan steady rate (10 req/sec)
- Jika bucket penuh (burst limit), request ditolak

### Konfigurasi Rate Limiting di Pharazon

```bash
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
```

### Testing Rate Limiting

#### Test 1: Normal Request (Tidak Melebihi Limit)
```bash
# Node Client
echo "nameserver 10.76.3.3" > /etc/resolv.conf

echo "==================================================="
echo "TEST 1: Normal request (tidak melebihi limit)"
echo "==================================================="

for i in {1..10}; do
    curl -s -o /dev/null -w "Request $i: Status %{http_code}\n" http://elros.k25.com/
    sleep 0.2  # 5 req/sec (di bawah limit 10 req/sec)
done
```

**Expected Output:**
```
Request 1: Status 200
Request 2: Status 200
Request 3: Status 200
...
Request 10: Status 200
```

**Analisis:** Semua request berhasil karena rate (5 req/sec) di bawah limit (10 req/sec)

#### Test 2: Burst Request (Melebihi Limit)
```bash
echo "==================================================="
echo "TEST 2: Burst request (melebihi limit)"
echo "==================================================="

for i in {1..30}; do
    curl -s -o /dev/null -w "Request $i: Status %{http_code}\n" http://elros.k25.com/ &
done
wait
```

**Expected Output:**
```
Request 1: Status 200
Request 2: Status 200
...
Request 20: Status 200
Request 21: Status 429
Request 22: Status 429
...
Request 30: Status 429
```

**Analisis:**
- Request 1-20: Berhasil (10 steady + 10 burst)
- Request 21-30: Ditolak dengan 429 (melebihi burst capacity)

#### Test 3: Apache Bench dengan Konkurensi Tinggi
```bash
echo "==================================================="
echo "TEST 3: Apache Bench dengan konkurensi tinggi"
echo "==================================================="

ab -n 1000 -c 50 http://elros.k25.com/
```

**Expected Output:**
```
Concurrency Level:      50
Time taken for tests:   45.678 seconds
Complete requests:      1000
Failed requests:        650
Non-2xx responses:      650
Requests per second:    21.89 [#/sec]
```

**Analisis:**
- Failed requests tinggi (650/1000 = 65%)
- Banyak request ditolak dengan 429
- Rate limiting berhasil melindungi backend

#### Verifikasi Error Log
```bash
# Node Elros
tail -50 /var/log/nginx/elros_error.log | grep "limiting requests"
```

**Expected Output:**
```
2025/10/21 10:30:45 [error] 1234#1234: *5678 limiting requests, excess: 20.500 by zone "laravel_limit", client: 10.76.4.4, server: elros.k25.com, request: "GET / HTTP/1.1"
```

**Penjelasan Error Log:**
- `limiting requests`: Request ditolak karena rate limit
- `excess: 20.500`: Melebihi burst limit sebanyak 20.5 requests
- `zone "laravel_limit"`: Zone yang enforce limit
- `client: 10.76.4.4`: IP address klien yang kena limit

#### Test 4: Rate Limiting di Pharazon
```bash
# Normal request
for i in {1..10}; do
    curl -u noldor:silvan -s -o /dev/null -w "Request $i: Status %{http_code}\n" http://pharazon.k25.com/
    sleep 0.2
done

# Burst request
for i in {1..30}; do
    curl -u noldor:silvan -s -o /dev/null -w "Request $i: Status %{http_code}\n" http://pharazon.k25.com/ &
done
wait
```

#### Test 5: Apache Bench di Pharazon
```bash
ab -n 1000 -c 50 -A noldor:silvan http://pharazon.k25.com/
```

**Expected Output:**
```
Complete requests:      1000
Failed requests:        XXX (banyak ditolak)
Non-2xx responses:      XXX (429 Too Many Requests)
```

### Analisis Rate Limiting

#### Hitung Rate Limit Hit
```bash
# Node Elros
tail -1000 /var/log/nginx/elros_access.log | awk '{print $9}' | grep 429 | wc -l
```

**Output:** Jumlah request yang ditolak (HTTP 429)

#### Distribusi Status Code
```bash
tail -1000 /var/log/nginx/elros_access.log | awk '{print $9}' | sort | uniq -c
```

**Expected Output:**
```
    350 200  (request berhasil)
    650 429  (request ditolak rate limit)
```

**Analisis:**
- 35% request berhasil (dalam limit)
- 65% request ditolak (melebihi limit)
- Rate limiting efektif melindungi backend

---

## Soal 20: Proxy Caching

### Tujuan
Mengimplementasikan proxy caching di Pharazon untuk meningkatkan performance dengan menyimpan response dari backend dan melayani dari cache untuk request berikutnya.

### Konfigurasi

#### Buat Directory Cache
```bash
# Node Pharazon
mkdir -p /var/cache/nginx/pharazon_cache
chown -R www-data:www-data /var/cache/nginx/pharazon_cache
chmod -R 755 /var/cache/nginx/pharazon_cache
```

**Penjelasan:**
- Directory untuk menyimpan cached files
- Owner `www-data` agar Nginx bisa write
- Permission `755` (rwxr-xr-x)

#### Update Konfigurasi Nginx dengan Caching
```bash
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
```

**Penjelasan Directive Caching:**

**`proxy_cache_path /var/cache/nginx/pharazon_cache`:**
- Path directory untuk cache storage

**`levels=1:2`:**
- Struktur directory hierarchy untuk cache files
- Level 1: 1 character subdirectory
- Level 2: 2 character subdirectory
- Contoh: `/var/cache/nginx/pharazon_cache/a/bc/xyz123...`
- Mencegah too many files dalam satu directory



