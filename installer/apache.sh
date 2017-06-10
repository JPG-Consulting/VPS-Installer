#!/bin/bash

function apache2_install {
  apt-get --yes install apache2
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install apache2."
    exit 1
  fi
}

function apache2_harden {
  if [ -e /etc/apache2/conf-enabled/security.conf ]; then
    sed -i 's/^ServerSignature On/ServerSignature Off/g' /etc/apache2/conf-enabled/security.conf
    sed -i 's/^ServerTokens \(OS\|Full\|Minimal\|Minor\|Major\)/ServerTokens Prod/g' /etc/apache2/conf-enabled/security.conf
  elif [ -e /etc/apache2/conf.d/security ]; then
    sed -i 's/^ServerSignature On/ServerSignature Off/g' /etc/apache2/conf.d/security
    sed -i 's/^ServerTokens \(OS\|Full\|Minimal\|Minor\|Major\)/ServerTokens Prod/g' /etc/apache2/conf.d/security
  fi
}
