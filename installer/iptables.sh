#!/bin/bash

if ! is_package_installed iptables-persistent; then
  echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
  echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections
  apt-get --yes install iptables-persistent
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install iptables-persistent."
    exit 1
  fi
fi

# Clear IPTables
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Enable stateful inspection
iptables -A INPUT   -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow all packets via lo
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# SSH
iptables -A INPUT  -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT

# HTTP and HTTPS (IPv4)
iptables -A INPUT -m state --state NEW,ESTABLISHED -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -m state --state NEW,ESTABLISHED -p tcp --dport 443 -j ACCEPT
# HTTP and HTTPS (IPv6)
iptables -A INPUT -m state --state NEW,ESTABLISHED -m tcp -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -m state --state NEW,ESTABLISHED -m tcp -p tcp --dport 443 -j ACCEPT

# FTP
iptables -A INPUT  -p tcp -m tcp --dport 21 -m conntrack --ctstate ESTABLISHED,NEW -j ACCEPT -m comment --comment "Allow ftp connections on port 21"
iptables -A OUTPUT -p tcp -m tcp --dport 21 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT -m comment --comment "Allow ftp connections on port 21"

iptables -A INPUT  -p tcp -m tcp --dport 20 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT -m comment --comment "Allow ftp connections on port 20"
iptables -A OUTPUT -p tcp -m tcp --dport 20 -m conntrack --ctstate ESTABLISHED -j ACCEPT -m comment --comment "Allow ftp connections on port 20"

iptables -A INPUT  -p tcp -m tcp --sport 1024: --dport 1024: -m conntrack --ctstate ESTABLISHED -j ACCEPT -m comment --comment "Allow passive inbound connections"
iptables -A OUTPUT -p tcp -m tcp --sport 1024: --dport 1024: -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT -m comment --comment "Allow passive inbound connections"

# IMAP port
iptables -A INPUT -m state --state NEW,ESTABLISHED -m tcp -p tcp --dport 143 -j ACCEPT
# Secure IMAP
# iptables -A INPUT -m state --state NEW,ESTABLISHED -m tcp -p tcp --dport 993 -j ACCEPT
# POP3
#iptables -A INPUT -m state --state NEW,ESTABLISHED -m tcp -p tcp --dport 110 -j ACCEPT
# Secure POP3
#iptables -A INPUT -m state --state NEW,ESTABLISHED -m tcp -p tcp --dport 995 -j ACCEPT

iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

iptables-save > /etc/network/iptables.up.rules
