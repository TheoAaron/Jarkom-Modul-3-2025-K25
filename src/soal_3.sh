# Node Minastir
apt-get install -y squid

cat > /etc/squid/squid.conf << EOF
http_port 8080
visible_hostname minastir

acl all src 0.0.0.0/0
http_access allow all

# Logging
access_log /var/log/squid/access.log squid
cache_log /var/log/squid/cache.log
EOF

service squid restart

# SEMUA NODE (kecuali Durin dan Minastir)
cat >> /etc/environment << EOF
http_proxy="http://10.76.5.2:8080"
https_proxy="http://10.76.5.2:8080"
ftp_proxy="http://10.76.5.2:8080"
EOF

export http_proxy="http://10.76.5.2:8080"
export https_proxy="http://10.76.5.2:8080"

cat > /etc/apt/apt.conf.d/proxy.conf << EOF
Acquire::http::Proxy "http://10.76.5.2:8080";
Acquire::https::Proxy "http://10.76.5.2:8080";
EOF

# TEST
# Node Minastir
service squid status
cat /etc/squid/squid.conf

netstat -tulpn | grep 8080
ss -tulpn | grep 8080

tail -f /var/log/squid/access.log

# Node manapun
env | grep proxy

curl -x http://10.76.5.2:8080 http://google.com
apt-get update
wget http://google.com

# Node Minastir

tail -f /var/log/squid/access.log