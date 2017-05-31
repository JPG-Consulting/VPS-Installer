#!ª/bin/bash

if ! is_package_installed apache2; then
  apt-get --yes install apache2
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install apache2."
    exit 1
  fi
fi

