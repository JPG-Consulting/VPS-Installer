#!/bin/bash

while true; do
  read -p "Username: " USER_NAME
  if [[ -n "$USER_NAME" ]]; then
    if id "$USER_NAME" >/dev/null 2>&1; then
        echo "Sorry, the user $USER_NAME already exists"
    else
        break;
    fi
  else
    echo "Sorry, username can not be empty"
  fi
done

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
