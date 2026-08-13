#!/bin/sh
# Docker-in-Docker setup for the ADLC agentic workspace pod.
#
# Starts dockerd inside the workspace so the Dev Containers CLI can build and
# run the project's devcontainer. When the Coder agent URL runs through the
# Docker bridge (host.docker.internal), extra NAT/DNS plumbing is applied so
# the devcontainer can reach the Coder server.

set -e

echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward >/dev/null

INITIALIZED=/home/coder/.dind-initialized
if [ -f "$INITIALIZED" ]; then
    echo "dind already initialized — starting docker"
    sudo service docker start
    exit 0
fi

# External access URL (e.g. https://coder.cne-ops.app): plain start is enough.
if [ "${CODER_AGENT_URL#*host.docker.internal}" = "$CODER_AGENT_URL" ]; then
    sudo service docker start
    touch "$INITIALIZED"
    exit 0
fi

# host.docker.internal access URL: Docker's bridge can shadow DNS resolution
# of the Coder server. Enable forwarding + NAT, then point the devcontainer's
# DNS at this pod so it can reach the agent.
sudo iptables -t nat -A POSTROUTING -j MASQUERADE
host_ip=$(getent hosts host.docker.internal | awk '{print $1}')

port="${CODER_AGENT_URL##*:}"
port="${port%%/*}"
case "$port" in
[0-9]*)
    sudo iptables -t nat -A PREROUTING -p tcp --dport "$port" -j DNAT --to-destination "$host_ip:$port"
    ;;
*)
    for p in 80 443; do
        sudo iptables -t nat -A PREROUTING -p tcp --dport "$p" -j DNAT --to-destination "$host_ip:$p"
    done
    ;;
esac

sudo service docker start

dns_ip=
while [ -z "$dns_ip" ]; do
    dns_ip=$(hostname -I | awk '{print $2}')
    [ -z "$dns_ip" ] && sleep 1
done

if ! command -v dnsmasq >/dev/null 2>&1; then
    sudo apt-get update -qq >/dev/null
    sudo apt-get install -y -qq dnsmasq >/dev/null
fi

printf 'no-hosts\naddress=/host.docker.internal/%s\nresolv-file=/etc/resolv.conf\nno-dhcp-interface=\nbind-interfaces\nlisten-address=127.0.0.1,%s\n' "$dns_ip" "$dns_ip" | sudo tee /etc/dnsmasq.conf >/dev/null
sudo service dnsmasq restart
printf '{"dns": ["%s"]}\n' "$dns_ip" | sudo tee /etc/docker/daemon.json >/dev/null
sudo service docker restart
touch "$INITIALIZED"
echo "dind initialized for host.docker.internal access URL"