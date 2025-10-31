# Node Amandil
# Verifikasi lease time
dhclient -r eth0
dhclient -v eth0

cat /var/lib/dhcp/dhclient.leases | grep lease-time
cat /var/lib/dhcp/dhclient.leases | grep "renew\|rebind\|expire"

# Verifikasi durasi:
# Manusia: default-lease-time 1800 (30 menit = setengah jam)
# max-lease-time 3600 (1 jam)
# renew time = 900 detik (setengah dari 1800 = 15 menit)
# rebind time = 1575 detik (7/8 dari 1800 = 26.25 menit)
# expire time = 3600 detik (1 jam)

# Node Gilgalad
# Verifikasi lease time
dhclient -r eth0
dhclient -v eth0

cat /var/lib/dhcp/dhclient.leases | grep lease-time
cat /var/lib/dhcp/dhclient.leases | grep "renew\|rebind\|expire"

# Peri: default-lease-time 600 (10 menit = seperenam jam)
# max-lease-time 3600 (1 jam)
# renew time = 300 detik (setengah dari 600 = 5 menit)
# rebind time = 525 detik (7/8 dari 600 = 8.75 menit)
# expire time = 3600 detik (1 jam)