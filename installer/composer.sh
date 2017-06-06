#!/bin/bash

function composer_install {
  local __composer=$(which composer)
  apt-get install --yes curl php5-cli git-core
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install composer requirements."
    exit 1
  fi
  
  if [ -z "$__composer" ]; then
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
  fi
}
