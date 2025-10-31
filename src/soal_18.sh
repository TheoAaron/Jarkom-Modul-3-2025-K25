# Node Palantir (Master)
apt-get update
apt-get install -y mariadb-server

# Backup konfigurasi
cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.bak

# Konfigurasi Master
cat >> /etc/mysql/mariadb.conf.d/50-server.cnf << EOF

# Replication Configuration - MASTER
server-id = 1
log_bin = /var/log/mysql/mysql-bin.log
binlog_do_db = laravel_db
bind-address = 0.0.0.0
EOF

# Kalau restart error baru pakai ini habis tuh restart lagi
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql
chmod 750 /var/log/mysql

service mariadb restart

# Buat user untuk replikasi
mysql << EOF
CREATE USER 'replication_user'@'%' IDENTIFIED BY 'replication_password';
GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%';
FLUSH PRIVILEGES;
FLUSH TABLES WITH READ LOCK;
EOF

# Catat posisi binary log
mysql -e "SHOW MASTER STATUS;"
# PENTING: Catat File dan Position untuk digunakan di Slave

# Contoh output:
# +------------------+----------+--------------+------------------+
# | File             | Position | Binlog_Do_DB | Binlog_Ignore_DB |
# +------------------+----------+--------------+------------------+
# | mysql-bin.000001 |      328 | laravel_db   |                  |
# +------------------+----------+--------------+------------------+

# Export database untuk initial data
mysqldump -u root laravel_db > /tmp/laravel_db.sql

# Unlock tables
mysql -e "UNLOCK TABLES;"

# Node Narvi (Slave)
apt-get update
apt-get install -y mariadb-server

# Backup konfigurasi
cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.bak

# Konfigurasi Slave
cat >> /etc/mysql/mariadb.conf.d/50-server.cnf << EOF

# Replication Configuration - SLAVE
server-id = 2
relay-log = /var/log/mysql/mysql-relay-bin.log
log_bin = /var/log/mysql/mysql-bin.log
binlog_do_db = laravel_db
bind-address = 0.0.0.0
EOF

# Kalau restart error baru pakai ini habis tuh restart lagi
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql
chmod 750 /var/log/mysql

service mariadb restart

# Buat database dan import initial data
mysql -e "CREATE DATABASE IF NOT EXISTS laravel_db;"

# Transfer file dari Palantir ke Narvi (gunakan scp atau cara lain)
# Atau copy manual file /tmp/laravel_db.sql

# Import data
mysql laravel_db < /tmp/laravel_db.sql

# Konfigurasi slave connection
# GANTI 'mysql-bin.000001' dan 328 dengan nilai dari SHOW MASTER STATUS di Palantir
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

# Cek status slave
mysql -e "SHOW SLAVE STATUS\G"
# Expected: Slave_IO_Running: Yes, Slave_SQL_Running: Yes

# TEST REPLIKASI

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

# Node Narvi (Slave)
echo "==================================================="
echo "TEST 1: Verifikasi tabel di Slave"
echo "==================================================="

# Tunggu beberapa detik untuk replikasi
sleep 3

mysql -e "USE laravel_db; SHOW TABLES;"
mysql -e "USE laravel_db; SELECT * FROM test_replication;"
# Expected: Tabel dan data yang sama dengan Master

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

# Node Narvi (Slave)
echo "==================================================="
echo "TEST 2: Verifikasi insert di Slave"
echo "==================================================="

sleep 3

mysql -e "USE laravel_db; SELECT COUNT(*) as total FROM test_replication;"
mysql -e "USE laravel_db; SELECT * FROM test_replication ORDER BY id DESC LIMIT 3;"
# Expected: Data terbaru dari Master muncul di Slave

# MONITORING REPLIKASI

# Node Narvi
echo "==================================================="
echo "STATUS REPLIKASI DETAIL:"
echo "==================================================="

mysql -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master|Last_Error"
# Expected:
# Slave_IO_Running: Yes
# Slave_SQL_Running: Yes
# Seconds_Behind_Master: 0
# Last_Error: (kosong)

# Node Palantir
echo "==================================================="
echo "MASTER STATUS:"
echo "==================================================="

mysql -e "SHOW MASTER STATUS;"
mysql -e "SHOW PROCESSLIST;" | grep "Binlog Dump"
# Expected: Ada proses "Binlog Dump" untuk slave connection

# TEST ERROR HANDLING
# Node Palantir

mysql laravel_db << EOF
UPDATE test_replication SET message = 'Updated from Master' WHERE id = 1;
EOF

mysql -e "USE laravel_db; SELECT * FROM test_replication WHERE id = 1;"

# Node Narvi
sleep 3
mysql -e "USE laravel_db; SELECT * FROM test_replication WHERE id = 1;"
# Expected: Data juga ter-update di Slave