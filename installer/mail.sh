#!/bin/bash
# References: https://wiki.debian.org/Postfix#Installing_and_Configuring_Postfix_on_Debian
#             https://www.debuntu.org/how-to-virtual-emails-accounts-with-postfix-and-dovecot/
#             https://wiki.gentoo.org/wiki/Complete_Virtual_Mail_Server/Linux_vmail_user
#             https://www.digitalocean.com/community/tutorials/how-to-configure-a-mail-server-using-postfix-dovecot-mysql-and-spamassassin

# Creating The Virtual Email User
if ! id -g "vmail" > /dev/null 2>&1; then
  groupadd -g 5000 vmail
fi

if ! id -u "vmail" >/dev/null 2>&1; then
  useradd -m -d /var/vmail -s /bin/false -u 5000 -g vmail vmail
  rm -rf /var/vmail/*
fi

if [ ! -d /var/vmail ]; then
  mkdir /var/vmail
fi

chown vmail:vmail /var/vmail
chmod 2770 /var/vmail

VMAIL_PASSWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9-_!@#^&*()_+{}|:<>=.;\-' | fold -w 30 | head -n1)

# ===========================================
#  MySQL
# ===========================================
if is_package_installed mysql-server; then

  mysql -uroot -p$MYSQL_ROOT_PASSWD << _EOF_
CREATE DATABASE IF NOT EXISTS vmail;
GRANT USAGE ON *.* TO vmail@'localhost' IDENTIFIED BY '$VMAIL_PASSWD';
GRANT ALL PRIVILEGES ON vmail.* TO vmail@'localhost';
_EOF_

  mysql -uvmail -p$VMAIL_PASSWD < $INSTALLER_DIR/installer/sql/vmail.sql
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

# backup Dovecot files
if [ ! -f /etc/dovecot/dovecot.conf.orig ]; then
  cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.orig
fi
if [ ! -f /etc/dovecot/conf.d/10-mail.conf.orig ]; then
 cp /etc/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf.orig
fi
if [ ! -f /etc/dovecot/conf.d/10-auth.conf.orig ]; then
  cp /etc/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf.orig
fi
if [ ! -f /etc/dovecot/dovecot-sql.conf.ext.orig ]; then
  cp /etc/dovecot/dovecot-sql.conf.ext /etc/dovecot/dovecot-sql.conf.ext.orig
fi
if [ ! -f /etc/dovecot/conf.d/10-master.conf.orig ]; then
  cp /etc/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf.orig
fi
if [ ! -f /etc/dovecot/conf.d/10-ssl.conf.orig ]; then
  cp /etc/dovecot/conf.d/10-ssl.conf /etc/dovecot/conf.d/10-ssl.conf.orig
fi
if [ ! -f /etc/dovecot/conf.d/auth-sql.conf.ext.orig]; then
  cp /etc/dovecot/conf.d/auth-sql.conf.ext /etc/dovecot/conf.d/auth-sql.conf.ext.orig
fi

sed -i 's/^mail_location =.*/mail_location = maildir:\/var\/vmail\/vhosts\/%d\/%n\//g' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/^#mail_uid =.*/mail_uid = vmail/g' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/^#mail_gid =.*/mail_gid = vmail/g' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/^#mail_privileged_group =.*/#mail_privileged_group = vmail/g' /etc/dovecot/conf.d/10-mail.conf


cat <<_EOF_ > /etc/dovecot/dovecot-sql.conf
driver = mysql
connect = host=127.0.0.1 dbname=vmail user=vmail password=$VMAIL_PASSWD
default_pass_scheme = PLAIN-MD5
password_query = SELECT password FROM virtual_users AS V LEFT JOIN virtual_domains AS D ON V.domain_id=D.id WHERE V.user='%n' AND D.name='%d'
_EOF_

cat <<_EOF_ >  /var/vmail/globalsieverc
require ["fileinto"];
# Move spam to spam folder
if anyof(header :contains "X-Spam-Flag" ["YES"], header :contains "X-DSPAM-Result" ["Spam"]) {
  fileinto "Spam";
  stop;
}
_EOF_

# ==========================================
#  Merge Postfix and Dovecot
# ==========================================

if [[ ! $(grep -F dovecot /etc/postfix/master.cf) ]]; then 
  echo "dovecot   unix  -       n       n       -       -       pipe" >> /etc/postfix/master.cf
  echo "   flags=DRhu user=vmail:vmail argv=/usr/lib/dovecot/dovecot-lda -f ${sender} -d ${recipient}" >> /etc/postfix/master.cf
fi

service dovecot restart
service postfix restart
