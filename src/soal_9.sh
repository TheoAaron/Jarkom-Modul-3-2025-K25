# Node Miriel, Celebrimbor, Gilgalad, Amandil
echo "nameserver 10.76.3.3" > /etc/resolv.conf

# Test setiap worker
lynx http://elendil.k25.com:8001
lynx http://isildur.k25.com:8002
lynx http://anarion.k25.com:8003

# Test API endpoint
curl http://elendil.k25.com:8001/api/airing
curl http://isildur.k25.com:8002/api/airing
curl http://anarion.k25.com:8003/api/airing

echo "nameserver 10.76.3.3" > /etc/resolv.conf


# Test API dengan curl
curl http://elendil.k25.com:8001/api/airing # Expected: JSON response dengan data airing
curl http://isildur.k25.com:8002/api/airing
curl http://anarion.k25.com:8003/api/airing

curl -s http://elendil.k25.com:8001/api/airing > /tmp/elendil.json
curl -s http://isildur.k25.com:8002/api/airing > /tmp/isildur.json
curl -s http://anarion.k25.com:8003/api/airing > /tmp/anarion.json
diff /tmp/elendil.json /tmp/isildur.json
diff /tmp/isildur.json /tmp/anarion.json