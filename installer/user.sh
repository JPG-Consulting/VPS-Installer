#!/bin/bash

while true; do
  read -p "Username: " USER_NAME
  if [[ -n "$USER_NAME" ]]; then
    if id "$USER_NAME" >/dev/null 2>&1; then
        echo "The user $USER_NAME already exists."
        if prompt_yn "Do you wish to use this user as non-privileged user?"; then
          break;
        fi
    else
     # Ask for a password for the new user
      read_password USER_PASSWD

      # Create the user right away
      adduser --gecos ",,," --disabled-password $USER_NAME
      if [ $? -ne 0 ]; then
        echo "Error: Failed to add user $USER_NAME."
        exit 1
      fi

      echo "$USER_NAME:$USER_PASSWD" | chpasswd
      if [ $? -ne 0 ]; then
        echo "Error: Failed to set the password for user $USER_NAME"
        exit 1
      fi

      break
    fi
  else
    echo "Sorry, username can not be empty"
  fi
done

# =====================================
#  Sudo
# =====================================
if ! is_package_installed sudo; then
  apt-get --yes install sudo
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install sudo."
    exit 1
  fi
fi

if ! id -nG "$USER_NAME" | grep -qw "sudo"; then
  usermod -aG sudo $USER_NAME
  if [ $? -ne 0 ]; then
    echo "Error: Failed to add $USER_NAME to the sudo group."
    exit 1
  fi
fi

# =====================================
#  SSH
# =====================================
if [ -f "/etc/ssh/sshd_config" ]; then
  #  Disable root login via SSH
  sed -i "s/#PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
  sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config

  # Filter SSH users
  if ! `egrep -v "^(#|$)" /etc/ssh/sshd_config | grep -i "^AllowGroups" | grep -iq "sudo"` ; then
    if `grep -iq "^AllowGroups" /etc/ssh/sshd_config` ; then
      sed -i "s/^\(AllowGroups.*\)/\1 sudo/g" /etc/ssh/sshd_config
     else
        echo "AllowGroups sudo" >> /etc/ssh/sshd_config
     fi
  fi
fi

if [ -d "/home/${USER_NAME}" ]; then
  if [ ! -d "/home/${USER_NAME}/.ssh" ]; then
    mkdir --parents "/home/${USER_NAME}/.ssh"
    chown "${USER_NAME}":"${USER_NAME}" "/home/${USER_NAME}/.ssh"
  fi
fi

if [ -e /etc/init.d/ssh ]; then
  service ssh restart
fi
