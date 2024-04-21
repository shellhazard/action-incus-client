#!/bin/sh
set -eu

# Check that we're root.
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as the root user."
    exit 1
fi

# Install curl if missing.
if ! command -v curl >/dev/null >/dev/null 2>&1; then
    apt-get update
    apt-get install curl --yes
fi

# Get the repository keyring key.
mkdir -p /etc/apt/keyrings/
curl -fsSL https://pkgs.zabbly.com/key.asc -o /etc/apt/keyrings/zabbly.asc

# Add the repository.
sh -c 'cat <<EOF > /etc/apt/sources.list.d/zabbly-incus-stable.sources
Enabled: yes
Types: deb
URIs: https://pkgs.zabbly.com/incus/stable
Suites: $(. /etc/os-release && echo ${VERSION_CODENAME})
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/zabbly.asc

EOF'

# Install Incus.
apt-get update
apt-get install incus-client --yes --no-install-recommends

exit 0