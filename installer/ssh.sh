#./bin/bash

if ! is_package_installed openssh-server; then
  apt-get --yes install openssh-server
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install openssh-server."
    exit 1
  fi
fi

# ===========================================
#  Harden SSH Server
# ===========================================

sed -i "s/#PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config

service ssh restart
