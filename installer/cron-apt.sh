 #!/bin/bash
 
if ! is_package_installed cron-apt; then
  apt-get --yes install cron-apt
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install cron-apt."
    exit 1
  fi
fi

cat >/etc/cron-apt/config <<EOL
# Configuration for cron-apt. For further information about the possible
# configuration settings see /usr/share/doc/cron-apt/README.gz.

#APTCOMMAND=/usr/bin/aptitude
#OPTIONS="-o quiet=1 -o Dir::Etc::SourceList=/etc/apt/sources.list"
#MAILTO="youremailaddress"
MAILON="always"
EOL

if [ ! -f /etc/cron-apt/action.d/5-security ]; then
  echo "upgrade -y -o APT::Get::Show-Upgraded=True" > /etc/cron-apt/action.d/5-security
  echo 'OPTIONS="-o quiet=1 -o Dir::Etc::SourceList=/etc/apt/sources.list.d/security.list -o Dir::Etc::SourceParts=\"/dev/null\""' > /etc/cron-apt/config.d/5-security
fi

cat >/etc/cron-apt/config <<EOL
#
# Apt sources.list limited to security update for cron-apt
#
deb http://security.debian.org/ wheezy/updates main contrib non-free
deb-src http://security.debian.org/ wheezy/updates main contrib non-free
EOL
