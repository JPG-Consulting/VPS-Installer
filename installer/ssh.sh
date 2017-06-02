#./bin/bash
# Reference: https://howto.biapy.com/en/debian-gnu-linux/system/security/harden-the-ssh-access-security-on-debian

if ! is_package_installed openssh-server; then
  apt-get --yes install openssh-server
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install openssh-server."
    exit 1
  fi
fi

# ===========================================
#  Disable root login via SSH
# ===========================================

sed -i "s/#PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config

# ===========================================
#  Filter SSH users
# ===========================================
if ! `egrep -v "^(#|$)" /etc/ssh/sshd_config | grep -i "^AllowGroups" | grep -iq "sudo"` ; then
   if `grep -iq "^AllowGroups" /etc/ssh/sshd_config` ; then
      sed -i "s/^\(AllowGroups.*\)/\1 sudo/g" /etc/ssh/sshd_config
   else
      echo "AllowGroups sudo" >> /etc/ssh/sshd_config
   fi
fi

#ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N "PASSPHRASE"

# ========================================
#  Restart the SSH server
# ========================================
service ssh restart
