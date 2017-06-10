#!/bin/bash
# here we ask for the questions needed to proceed with the system installation

function read_mysql_password {
  local __resultvar=$1
  local __password
  local __password2

  while true; do
    read -sp "MySQL root password: " __password
    echo

    if [[ -n "$__password" ]]; then
      read -sp "Retype MySQL root password: " __password2
      echo

      [ "$__password" = "$__password2" ] && break
      echo "Sorry, passwords do not match"
    else
      echo "Sorry, password can not be empty"
    fi
  done

  if [[ "$__resultvar" ]]; then
    eval $__resultvar="'$__password'"
  else
    echo "$__password"
  fi
}

read_mysql_password MYSQL_ROOT_PASSWD

if ! is_package_installed bind9; then
  prompt_yn "Install bind9 DNS server?" INSTALL_BIND9
else
  INSTALL_BIND9=0
fi
