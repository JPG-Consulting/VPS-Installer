#!/bin/bash

if ! is_package_installed mysql-server; then
  apt-get --yes install mysql-server
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install mysql-server."
    exit 1
  fi
fi

