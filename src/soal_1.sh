# SETUP SEMUA NODE
# Node Durin
auto lo
iface lo inet loopback
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 10.76.1.1
    netmask 255.255.255.0

auto eth2
iface eth2 inet static
    address 10.76.2.1
    netmask 255.255.255.0

auto eth3
iface eth3 inet static
    address 10.76.3.1
    netmask 255.255.255.0

auto eth4
iface eth4 inet static
    address 10.76.4.1
    netmask 255.255.255.0

auto eth5
iface eth5 inet static
    address 10.76.5.1
    netmask 255.255.255.0

echo 1 > /proc/sys/net/ipv4/ip_forward
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.conf

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE -s 10.76.0.0/16

iptables -A FORWARD -i eth1 -o eth2 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth3 -j ACCEPT
iptables -A FORWARD -i eth3 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth3 -j ACCEPT
iptables -A FORWARD -i eth3 -o eth2 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth4 -j ACCEPT
iptables -A FORWARD -i eth4 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth5 -j ACCEPT
iptables -A FORWARD -i eth5 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth4 -j ACCEPT
iptables -A FORWARD -i eth4 -o eth2 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth5 -j ACCEPT
iptables -A FORWARD -i eth5 -o eth2 -j ACCEPT
iptables -A FORWARD -i eth3 -o eth4 -j ACCEPT
iptables -A FORWARD -i eth4 -o eth3 -j ACCEPT
iptables -A FORWARD -i eth3 -o eth5 -j ACCEPT
iptables -A FORWARD -i eth5 -o eth3 -j ACCEPT
iptables -A FORWARD -i eth4 -o eth5 -j ACCEPT
iptables -A FORWARD -i eth5 -o eth4 -j ACCEPT

iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth3 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth4 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth5 -o eth0 -j ACCEPT

iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth3 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth4 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth5 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Node Elendil
auto eth0
iface eth0 inet static
    address 10.76.1.2
    netmask 255.255.255.0
    gateway 10.76.1.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Isildur
auto eth0
iface eth0 inet static
    address 10.76.1.3
    netmask 255.255.255.0
    gateway 10.76.1.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Anarion
auto eth0
iface eth0 inet static
    address 10.76.1.4
    netmask 255.255.255.0
    gateway 10.76.1.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Miriel
auto eth0
iface eth0 inet static
    address 10.76.1.5
    netmask 255.255.255.0
    gateway 10.76.1.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Amandil
auto eth0
iface eth0 inet dhcp
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Elros
auto eth0
iface eth0 inet static
    address 10.76.1.7
    netmask 255.255.255.0
    gateway 10.76.1.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Gilgalad
auto eth0
iface eth0 inet dhcp
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Celebrimbor
auto eth0
iface eth0 inet static
    address 10.76.2.3
    netmask 255.255.255.0
    gateway 10.76.2.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Pharazon
auto eth0
iface eth0 inet static
    address 10.76.2.4
    netmask 255.255.255.0
    gateway 10.76.2.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Galadriel
auto eth0
iface eth0 inet static
    address 10.76.2.5
    netmask 255.255.255.0
    gateway 10.76.2.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Celeborn
auto eth0
iface eth0 inet static
    address 10.76.2.6
    netmask 255.255.255.0
    gateway 10.76.2.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Oropher
auto eth0
iface eth0 inet static
    address 10.76.2.7
    netmask 255.255.255.0
    gateway 10.76.2.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Khamul (Client-Fixed-Address)
auto eth0
iface eth0 inet dhcp
    hwaddress ether 02:42:dc:08:82:00
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Erendis
auto eth0
iface eth0 inet static
    address 10.76.3.3
    netmask 255.255.255.0
    gateway 10.76.3.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Amdir
auto eth0
iface eth0 inet static
    address 10.76.3.4
    netmask 255.255.255.0
    gateway 10.76.3.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Aldarion
auto eth0
iface eth0 inet static
    address 10.76.4.2
    netmask 255.255.255.0
    gateway 10.76.4.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Palantir
auto eth0
iface eth0 inet static
    address 10.76.4.3
    netmask 255.255.255.0
    gateway 10.76.4.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Narvi
auto eth0
iface eth0 inet static
    address 10.76.4.4
    netmask 255.255.255.0
    gateway 10.76.4.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Minastir
auto eth0
iface eth0 inet static
    address 10.76.5.2
    netmask 255.255.255.0
    gateway 10.76.5.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf


# TEST
# Jaga-jaga jika belum install
apt-get update && apt-get install -y nano dnsutils lynx htop curl apache2-utils

# Node manapun
ping -c 3 8.8.8.8
ping -c 3 google.com