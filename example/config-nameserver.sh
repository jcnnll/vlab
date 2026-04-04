sudo mkdir -p /etc/resolver
echo "nameserver 192.168.2.10" | sudo tee /etc/resolver/vlab >/dev/null
