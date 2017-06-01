 #!/bin/bash
 
if ! is_package_installed cron-apt; then
  apt-get --yes install cron-apt
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install cron-apt."
    exit 1
  fi
fi

sudo cat >/etc/cron-apt/config <<EOL
# Configuration for cron-apt. For further information about the possible
# configuration settings see /usr/share/doc/cron-apt/README.gz.

#APTCOMMAND=/usr/bin/aptitude
#OPTIONS="-o quiet=1 -o Dir::Etc::SourceList=/etc/apt/sources.list"
#MAILTO="youremailaddress"
MAILON="always"
EOL
