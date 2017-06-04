#!/bin/bash
# References: https://wiki.debian.org/Postfix#Installing_and_Configuring_Postfix_on_Debian
#             https://www.debuntu.org/how-to-virtual-emails-accounts-with-postfix-and-dovecot/

# Creating The Virtual Email User
if ! id -g "vmail" > /dev/null 2>&1; then
  groupadd -g 5000 vmail
fi

if ! id -u "vmail" >/dev/null 2>&1; then
  useradd -m -d /var/vmail -s /bin/false -u 5000 -g vmail vmail
fi

if [ ! -d /var/vmail ]; then
  mkdir /var/vmail
fi

chown vmail:vmail /var/vmail

# ===========================================
#  MySQL
# ===========================================
if is_package_installed mysql-server; then
  service mysql stop
  mysqld_safe --skip-grant-tables &

  i="0"
  while [ $i -lt 10 ]; do
    sleep 1
    if [ -e /var/run/mysqld/mysqld.sock ]; then
      break
    fi
    i=$[$i+1]
  done

  mysql << _EOF_
CREATE DATABASE vmail;
GRANT USAGE ON *.* TO vmail@'localhost' IDENTIFIED BY 'vmailpass';
GRANT ALL PRIVILEGES ON vmail.* TO vmail@'localhost';
USE vmail;
DROP TABLE IF EXISTS `virtual_domains`;
CREATE TABLE `virtual_domains` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `UNIQUE_NAME` (`name`)
) ENGINE=InnoDB ;
DROP TABLE IF EXISTS `virtual_aliases`;
CREATE TABLE `virtual_aliases` (
  `id` int(11) NOT NULL auto_increment,
  `domain_id` int(11) NOT NULL,
  `source` varchar(40) NOT NULL,
  `destination` varchar(80) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `domain_id` (`domain_id`),
  CONSTRAINT `virtual_aliases_ibfk_1` FOREIGN KEY (`domain_id`) REFERENCES `virtual_domains` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB;
DROP TABLE IF EXISTS `virtual_users`;
CREATE TABLE `virtual_users` (
  `id` int(11) NOT NULL auto_increment,
  `domain_id` int(11) NOT NULL,
  `user` varchar(40) NOT NULL,
  `password` varchar(32) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `UNIQUE_EMAIL` (`domain_id`,`user`),
  CONSTRAINT `virtual_users_ibfk_1` FOREIGN KEY (`domain_id`) REFERENCES `virtual_domains` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB;
_EOF_
  
  killall -9 mysqld_safe mysqld
  service mysql stop
  service mysql start
fi

# ===========================================
#  Postfix SMTP
# ===========================================

if ! is_package_installed postfix; then
  # TODO: change this with the hostname
  debconf-set-selections <<< "postfix postfix/mailname string '$HOSTNAME'"
  debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

  if is_package_installed mysql-server; then
    apt-get --yes install postfix postfix-mysql
  else
    apt-get --yes install postfix
  fi
  
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install postfix."
    exit 1
  fi
elif ! is_package_installed postfix-mysql; then
  apt-get --yes install postfix-mysql
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install postfix-mysql."
    exit 1
  fi
fi

# Don't run postfix until it is secured!
service postfix stop

# Postfix basic setup
# Add your domain to the config files, so others can't abuse your mailsystem:
if [ -f /etc/mailname ]; then
  postconf -e "myorigin = /etc/mailname"
else
  postconf -e "myorigin = $HOSTNAME"
fi

# Add your hostname (computer name). (Use command "hostname" at the command-line to display your hostname if not sure.)
postconf -e "myhostname=$HOSTNAME"
# Now add the domain names that your system will handle.
postconf -e "relay_domains = $HOSTNAME"

postconf -e "inet_interfaces = all" 
postconf -e "inet_protocols = ipv4"

postconf -e 'smtpd_helo_required = yes'
postconf -e 'disable_vrfy_command = yes'


# ===========================================
#  Dovecot IMAP
# ===========================================

if ! is_package_installed dovecot-imapd; then
  if ! is_package_installed dovecot-common; then
    apt-get --yes install dovecot-imapd dovecot-common
  else
    apt-get --yes install dovecot-imapd
  fi
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install dovecot-imapd."
    exit 1
  fi
fi

# ==========================================
#  Merge Postfix and Dovecot
# ==========================================

if [[ ! $(grep -F dovecot /etc/postfix/master.cf) ]]; then 
  echo "dovecot   unix  -       n       n       -       -       pipe" >> /etc/postfix/master.cf
  echo "   flags=DRhu user=vmail:vmail argv=/usr/lib/dovecot/dovecot-lda -f ${sender} -d ${recipient}" >> /etc/postfix/master.cf
fi
