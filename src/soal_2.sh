# Node Aldarion
apt-get update && apt-get install -y isc-dhcp-server

# Konfigurasi interface - hanya IPv4, disable IPv6
echo 'INTERFACESv4="eth0"' > /etc/default/isc-dhcp-server
echo 'INTERFACESv6=""' >> /etc/default/isc-dhcp-server

cat > /etc/dhcp/dhcpd.conf << EOF
# Manusia
subnet 10.76.1.0 netmask 255.255.255.0 {
    range 10.76.1.6 10.76.1.34;
    range 10.76.1.68 10.76.1.94;
    option routers 10.76.1.1;
    option broadcast-address 10.76.1.255;
    option domain-name-servers 10.76.3.3;
    default-lease-time 1800;  # 30 menit
    max-lease-time 3600;      # 1 jam
}

# Peri
subnet 10.76.2.0 netmask 255.255.255.0 {
    range 10.76.2.35 10.76.2.67;
    range 10.76.2.96 10.76.2.121;
    option routers 10.76.2.1;
    option broadcast-address 10.76.2.255;
    option domain-name-servers 10.76.3.3;
    default-lease-time 600;   # 10 menit (1/6 jam)
    max-lease-time 3600;      # 1 jam
}

# Fixed Address
subnet 10.76.3.0 netmask 255.255.255.0 {
    option routers 10.76.3.1;
    option broadcast-address 10.76.3.255;
    option domain-name-servers 10.76.3.3;
}

# Aldarion
subnet 10.76.4.0 netmask 255.255.255.0 {
    option routers 10.76.4.1;
    option broadcast-address 10.76.4.255;
    option domain-name-servers 10.76.3.3;
}

# Host Khamul dengan Fixed Address
host Khamul {
    hardware ethernet 02:42:dc:08:82:00;
    fixed-address 10.76.3.95;
}
EOF

service isc-dhcp-server restart

# Node Durin
apt-get update && apt-get install -y isc-dhcp-relay

echo 'SERVERS="10.76.4.2"' > /etc/default/isc-dhcp-relay
echo 'INTERFACES="eth1 eth2 eth3 eth4"' >> /etc/default/isc-dhcp-relay
echo 'OPTIONS=""' >> /etc/default/isc-dhcp-relay

echo 'net.ipv4.ip_forward=1' > /etc/sysctl.conf
sysctl -p

service isc-dhcp-relay restart

# TEST

# Node Aldarion
service isc-dhcp-server status
cat /etc/dhcp/dhcpd.conf
cat /etc/default/isc-dhcp-server
cat /var/lib/dhcp/dhcpd.leases

# Node Durin
service isc-dhcp-relay status
cat /etc/default/isc-dhcp-relay
cat /proc/sys/net/ipv4/ip_forward

# Node Gilgalad
apt-get update
apt-get install -y isc-dhcp-client

ip addr flush dev eth0
ip route del default

dhclient -v eth0

ip addr show eth0

ip link show eth0 | grep ether

ping -c 3 10.76.1.1

# Jika Error
echo "nameserver 192.168.122.1" > /etc/resolv.conf
ip addr add 10.76.1.6/24 dev eth0
ip route add default via 10.76.1.1

# Node Amandil
apt-get update
apt-get install -y isc-dhcp-client

ip addr flush dev eth0
ip route del default

dhclient -v eth0

ip addr show eth0

ip link show eth0 | grep ether

ping -c 3 10.76.1.1

# Jika Error
echo "nameserver 192.168.122.1" > /etc/resolv.conf
ip addr add 10.76.1.6/24 dev eth0
ip route add default via 10.76.1.1

# Node Khamul
apt-get update
apt-get install -y isc-dhcp-client

ip addr flush dev eth0
ip route del default

dhclient -v eth0

# IP yang didapat harus 10.76.3.95)
ip addr show eth0

# Hardware address harus 02:42:dc:08:82:00)
ip link show eth0 | grep ether

# Jika error
echo "nameserver 192.168.122.1" > /etc/resolv.conf
ip addr add 10.76.3.95/24 dev eth0
ip route add default via 10.76.3.1