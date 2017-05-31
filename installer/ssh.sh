#./bin/bash

if ! is_package_installed openssh-server; then
  apt-get install openssh-server --yes
else
  echo "OpenSSH is already installed."
fi

echo "Username is $USER_NAME"
