# Node Amandil
dhclient -r eth0
dhclient -v eth0

cat /var/lib/dhcp/dhclient.leases | grep lease-time
cat /var/lib/dhcp/dhclient.leases | grep "renew\|rebind\|expire"

# Hitung durasi
# renew time = 15 menit (setengah dari lease time)
# rebind time = 26.25 menit (7/8 dari lease time)
# expire time = 60 menit (max-lease-time)