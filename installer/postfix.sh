#!/bin/bash

function postfix_install {
  # TODO: change this with the hostname
  debconf-set-selections <<< "postfix postfix/mailname string '$HOSTNAME'"
  debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

  apt-get --yes install postfix postfix-mysql
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install postfix."
    exit 1
  fi
}

function postfix_baseconfig {
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

  # Link the mailbox uid and gid to postfix.
  postconf -e "virtual_uid_maps = static:5000"
  postconf -e "virtual_gid_maps = static:5000"
 
  # Set the base address for all virtual mailboxes
  postconf -e "virtual_mailbox_base = /var/vmail"

  postconf -e "virtual_alias_domains ="
  postconf -e "virtual_mailbox_domains = mysql:/etc/postfix/virtual/mysql-virtual-mailbox-domains.cf"
  postconf -e "virtual_mailbox_maps = mysql:/etc/postfix/virtual/mysql-virtual-mailbox-maps.cf"
  postconf -e "virtual_alias_maps = mysql:/etc/postfix/virtual/mysql-virtual-alias-maps.cf, mysql:/etc/postfix/virtual/mysql-virtual-email2email.cf"
  postconf -e "virtual_transport = dovecot"
  postconf -e "dovecot_destination_recipient_limit = 1"

  if [ ! -d /etc/postfix/virtual ]; then
    mkdir /etc/postfix/virtual
  fi

  cat <<_EOF_ > /etc/postfix/virtual/mysql-virtual-mailbox-maps.cf
user = vmail
password = $VMAIL_PASSWD
hosts = 127.0.0.1
dbname = vmail
query = SELECT 1 FROM virtual_users AS U LEFT JOIN virtual_domains AS D ON U.domain_id=D.id WHERE CONCAT(U.user, '@',D.name)='%s'
_EOF_

  cat <<_EOF_ > /etc/postfix/virtual/mysql-virtual-mailbox-domains.cf
user = vmail
password = $VMAIL_PASSWD
hosts = 127.0.0.1
dbname = vmail
query = SELECT 1 FROM virtual_domains WHERE name='%s'
_EOF_

  cat <<_EOF_ > /etc/postfix/virtual/mysql-virtual-alias-maps.cf
user = vmail
password = $VMAIL_PASSWD
hosts = 127.0.0.1
dbname = vmail
query = SELECT destination FROM virtual_aliases AS A LEFT JOIN virtual_domains AS D ON A.domain_id=D.id WHERE CONCAT(A.source, '@', D.name)='%s'
_EOF_

  cat <<_EOF_ > /etc/postfix/virtual/mysql-virtual-email2email.cf
user = vmail
password = $VMAIL_PASSWD
hosts = 127.0.0.1
dbname = vmail
query = SELECT CONCAT(U.user, '@',D.name) FROM virtual_users AS U LEFT JOIN virtual_domains AS D ON U.domain_id=D.id WHERE CONCAT(U.user, '@',D.name)='%s'
_EOF_

  chown root:postfix -R /etc/postfix/virtual
  chmod 640 -R /etc/postfix/virtual
}

postfix_mysql_accounts {
  mysql -uroot -p$MYSQL_ROOT_PASSWD << _EOF_
CREATE DATABASE IF NOT EXISTS vmail;
GRANT USAGE ON *.* TO vmail@'localhost' IDENTIFIED BY '$VMAIL_PASSWD';
GRANT ALL PRIVILEGES ON vmail.* TO vmail@'localhost';
_EOF_

  mysql -uvmail -p$VMAIL_PASSWD < $INSTALLER_DIR/installer/sql/vmail.sql

  mysql -uvmail -p$VMAIL_PASSWD << _EOF_
USE vmail;
INSERT INTO virtual_domains ('name') VALUES ('$HOSTNAME');
_EOF_

}