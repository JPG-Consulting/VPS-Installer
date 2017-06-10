#!/bin/bash

function systemd_install {
  if ! is_package_installed systemd; then
    if ! is_package_installed systemd-sysv; then
      apt-get --yes install systemd systemd-sysv
      if [ $? -ne 0 ]; then
        echo "Error: Failed to install systemd."
        exit 1
      fi
    else
      apt-get --yes install systemd
      if [ $? -ne 0 ]; then
        echo "Error: Failed to install systemd."
        exit 1
      fi
    fi
  elif ! is_package_installed systemd-sysv; then
    apt-get --yes install systemd-sysv
    if [ $? -ne 0 ]; then
      echo "Error: Failed to install systemd."
      exit 1
    fi
  fi
}
