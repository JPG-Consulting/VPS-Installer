#ª/bin/bash
# Reference: https://wiki.debian.org/Bind9#Bind_Chroot
if ! is_package_installed bind9; then
  apt-get --yes install bind9
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install bind9."
    exit 1
  fi
fi

service bind9 stop

if [ ! -f "/etc/systemd/system/bind9.service" ]; then
  touch /etc/systemd/system/bind9.service

  echo "[Unit]" >> /etc/systemd/system/bind9.service
  echo "Description=BIND Domain Name Server" >> /etc/systemd/system/bind9.service
  echo "Documentation=man:named(8)" >> /etc/systemd/system/bind9.service
  echo "After=network.target" >> /etc/systemd/system/bind9.service
  echo "" >> /etc/systemd/system/bind9.service
  echo "[Service]" >> /etc/systemd/system/bind9.service
  echo "ExecStart=/usr/sbin/named -f -u bind -t /var/bind9/chroot" >> /etc/systemd/system/bind9.service
  echo "ExecReload=/usr/sbin/rndc reload" >> /etc/systemd/system/bind9.service
  echo "ExecStop=/usr/sbin/rndc stop" >> /etc/systemd/system/bind9.service
  echo "" >> /etc/systemd/system/bind9.service
  echo "[Install]" >> /etc/systemd/system/bind9.service
  echo "WantedBy=multi-user.target" >> /etc/systemd/system/bind9.service

  systemctl reenable bind9
fi

# Create the chroot directory structure
mkdir -p /var/bind9/chroot/{etc,dev,var/cache/bind,var/run/named}

# Create the required device special files and set the correct permissions
if [ ! -e "/var/bind9/chroot/dev/null" ]; then
  mknod /var/bind9/chroot/dev/null c 1 3
fi
if [ ! -e "/var/bind9/chroot/dev/random" ]; then
  mknod /var/bind9/chroot/dev/random c 1 8
fi
chmod 660 /var/bind9/chroot/dev/{null,random}

# Move the current config directory into the new chroot directory
if [ ! -d "/var/bind9/chroot/etc/bind" ]; then
  mv /etc/bind /var/bind9/chroot/etc
fi

# Now create a symbolic link in /etc for compatibility
if [ ! -e "/var/bind9/chroot/etc/bind" ]; then
  ln -s /var/bind9/chroot/etc/bind /etc/bind
fi

# If you want to use the local timezone in the chroot (e.g. for syslog)
cp /etc/localtime /var/bind9/chroot/etc/

# Change the ownership on the files you've just moved over and the rest of the newly created chroot directory structure
chown bind:bind /var/bind9/chroot/etc/bind/rndc.key
chmod 775 /var/bind9/chroot/var/{cache/bind,run/named}
chgrp bind /var/bind9/chroot/var/{cache/bind,run/named}

# Edit the PIDFILE variable in /etc/init.d/bind9 to the correct path:
sed -i 's/PIDFILE=\/var\/run\/named\/named.pid/PIDFILE=\/var\/bind9\/chroot\/var\/run\/named\/named.pid/g' /etc/init.d/bind9

# Tell rsyslog to listen to the bind logs in the correct place
echo "\$AddUnixListenSocket /var/bind9/chroot/dev/log" > /etc/rsyslog.d/bind-chroot.conf

# Restart rsyslog and start bind
service rsyslog restart
service bind9 start
