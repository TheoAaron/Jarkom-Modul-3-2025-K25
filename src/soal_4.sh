# Node Erendis
apt-get install -y bind9

cat > /etc/bind/named.conf.local << EOF
zone "k25.com" {
    type master;
    file "/etc/bind/jarkom/k25.com";
    allow-transfer { 10.76.3.4; };
};
EOF

mkdir -p /etc/bind/jarkom

cat > /etc/bind/jarkom/k25.com << EOF
\$TTL    604800
@       IN      SOA     k25.com. root.k25.com. (
                        2024102801      ; Serial
                        604800          ; Refresh
                        86400           ; Retry
                        2419200         ; Expire
                        604800 )        ; Negative Cache TTL
;
@               IN      NS      ns1.k25.com.
@               IN      NS      ns2.k25.com.
ns1             IN      A       10.76.3.3
ns2             IN      A       10.76.3.4

; Node Records
palantir        IN      A       10.76.4.3
narvi           IN      A       10.76.4.4
elros           IN      A       10.76.1.7
pharazon        IN      A       10.76.2.4
elendil         IN      A       10.76.1.2
isildur         IN      A       10.76.1.3
anarion         IN      A       10.76.1.4
galadriel       IN      A       10.76.2.5
celeborn        IN      A       10.76.2.6
oropher         IN      A       10.76.2.7
EOF

cat > /etc/bind/named.conf.options << EOF
options {
    directory "/var/cache/bind";
    allow-query { any; };
    auth-nxdomain no;
    listen-on-v6 { any; };
};
EOF

service bind9 restart

# Node Amdir
apt-get install -y bind9

cat > /etc/bind/named.conf.local << EOF
zone "k25.com" {
    type slave;
    file "/var/lib/bind/k25.com";
    masters { 10.76.3.3; };
};
EOF

cat > /etc/bind/named.conf.options << EOF
options {
    directory "/var/cache/bind";
    allow-query { any; };
    auth-nxdomain no;
    listen-on-v6 { any; };
};
EOF

service bind9 restart