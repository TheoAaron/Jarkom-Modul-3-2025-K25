# Node Minastir
apt-get update
apt-get install -y bind9 bind9utils bind9-doc dnsutils

cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bak

cat > /etc/bind/named.conf.options << EOF
options {
    directory "/var/cache/bind";

    forwarders {
        8.8.8.8;
        8.8.4.4;
        1.1.1.1;
    };

    forward only;

    allow-query { 
        10.76.0.0/16;
        localhost;
    };
    listen-on { any; };
    listen-on-v6 { none; };

    dnssec-validation auto;
    auth-nxdomain no;
    recursion yes;
    allow-recursion { 
        10.76.0.0/16;
        localhost;
    };
};
EOF

service named restart

# SEMUA NODE (kecuali Durin dan Minastir)
cat > /etc/resolv.conf << EOF
nameserver 10.76.5.2
nameserver 8.8.8.8
EOF

# TEST
# Node Minastir
service named status
cat /etc/bind/named.conf.options

netstat -tulpn | grep named
ss -tulpn | grep named

nslookup google.com
dig google.com
host google.com

tail -n 20 /var/log/syslog | grep named

# Node manapun kecuali Durin dan Minastir
cat /etc/resolv.conf

nslookup google.com 10.76.5.2
dig @10.76.5.2 google.com
host google.com 10.76.5.2
ping -c 3 google.com

nslookup k25.com 10.76.5.2
dig @10.76.5.2 k25.com