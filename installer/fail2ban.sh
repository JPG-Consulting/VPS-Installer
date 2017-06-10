#!/bin/bash

function fail2ban_install {
  apt-get --yes install fail2ban
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install fail2ban."
    exit 1
  fi
}

# ============================================
#  SSH
# ============================================

function fail2ban_ssh {
  if [ ! -e '/etc/fail2ban/jail.local' ]; then
   touch '/etc/fail2ban/jail.local'
  fi

  if [ -z "$(command grep "\[ssh-ddos\]" '/etc/fail2ban/jail.local')" ]; then
    echo "[ssh-ddos]" >> '/etc/fail2ban/jail.local'
    echo "enabled = true" >> '/etc/fail2ban/jail.local'
    echo "" >> '/etc/fail2ban/jail.local'
    echo "[pam-generic]" >> '/etc/fail2ban/jail.local'
    echo "enabled = true" >> '/etc/fail2ban/jail.local'
  fi
}
