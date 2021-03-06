#!/bin/bash

# Check if a package is installed.
# Return 0 (true) is installed or 1 (false) if not installed
function is_package_installed() {
    if [ $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        return 1
    else
        return 0
    fi
}

# prompt for a y/n questions
#
# Usage: prompt_yn "Should I continue?"
#
function prompt_yn() {
  echo -n "$1 [y/n]: "

  while true; do
    read -n 1 -s value;
    if [[ $value == "y" ]] || [[ $value == "Y" ]];  then
      echo "y"
      return 0
    elif [[ $value == "n" ]] || [[ $value == "N" ]]; then
      echo "n"
      return 1
    fi
  done
}

# Reads a password with confirmation.
#
# usage: read_password [VAR_NAME]
#
function read_password {
  local __resultvar=$1
  local __password
  local __password2

  while true; do
    read -sp "Enter new password: " __password
    echo

    if [[ -n "$__password" ]]; then
      read -sp "Retype new password: " __password2
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
