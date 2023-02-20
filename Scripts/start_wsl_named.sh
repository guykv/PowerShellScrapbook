#!/bin/env bash

if ! [ $(id -u) = 0 ]; then
    echo "The script needs to be run as root" >&2
    exit 1
fi

WSL_IP=$(/mnt/c/Windows/system32/wsl.exe hostname -I)
cat > /etc/bind/zones/forward.docker.localhost <<- EOF
\$TTL    604800
@       IN      SOA     ns.docker.localhost. docker.localhost. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.docker.localhost.
@       IN      A       $WSL_IP 
*       IN      A       $WSL_IP
EOF

service named start

