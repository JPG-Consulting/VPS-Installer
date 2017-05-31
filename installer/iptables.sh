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


