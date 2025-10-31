# Node Erendis
cat > /etc/bind/jarkom/k25.com << EOF
\$TTL    604800
@       IN      SOA     k25.com. root.k25.com. (
                        2024102802      ; Serial (increment!)
                        604800          ; Refresh
                        86400           ; Retry
                        2419200         ; Expire
                        604800 )        ; Negative Cache TTL
;
@               IN      NS      ns1.k25.com.
@               IN      NS      ns2.k25.com.
ns1             IN      A       10.76.3.3
ns2             IN      A       10.76.3.4

; CNAME untuk www
www             IN      CNAME   k25.com.

; TXT Records
@               IN      TXT     "Cincin Sauron: elros.k25.com"
@               IN      TXT     "Aliansi Terakhir: pharazon.k25.com"

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

cat > /etc/bind/named.conf.local << EOF
zone "k25.com" {
    type master;
    file "/etc/bind/jarkom/k25.com";
    allow-transfer { 10.76.3.4; };
};

# Reverse zone untuk Erendis (subnet 10.76.3.0/24)
zone "3.76.10.in-addr.arpa" {
    type master;
    file "/etc/bind/jarkom/3.76.10.in-addr.arpa";
    allow-transfer { 10.76.3.4; };
};
EOF

cat > /etc/bind/jarkom/3.76.10.in-addr.arpa << EOF
\$TTL    604800
@       IN      SOA     k25.com. root.k25.com. (
                        2024102801      ; Serial
                        604800          ; Refresh
                        86400           ; Retry
                        2419200         ; Expire
                        604800 )        ; Negative Cache TTL
;
@       IN      NS      ns1.k25.com.
@       IN      NS      ns2.k25.com.

; PTR Records untuk reverse lookup
3       IN      PTR     ns1.k25.com.    ; 10.76.3.3 -> ns1.k25.com (Erendis)
4       IN      PTR     ns2.k25.com.    ; 10.76.3.4 -> ns2.k25.com (Amdir)
EOF

service named restart

# Node Amdir
cat >> /etc/bind/named.conf.local << EOF
zone "3.76.10.in-addr.arpa" {
    type slave;
    file "/var/lib/bind/3.76.10.in-addr.arpa";
    masters { 10.76.3.3; };
};
EOF

service named restart

# TEST

# Node Erendis
dig @localhost www.k25.com
dig @localhost k25.com TXT
dig -x 10.76.3.3 @localhost
dig -x 10.76.3.4 @localhost

# Node Amdir
dig @localhost www.k25.com
dig @localhost k25.com TXT
dig -x 10.76.3.3 @localhost

# Node Client
echo "nameserver 10.76.3.3" > /etc/resolv.conf
nslookup www.k25.com
dig k25.com TXT
host 10.76.3.3
host 10.76.3.4