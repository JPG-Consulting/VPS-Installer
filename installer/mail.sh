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
  postfix_mysql_accounts
fi

# ===========================================
#  Postfix SMTP
# ===========================================

if ! is_package_installed postfix; then
  postfix_install
fi
postfix_baseconfig

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
if [ ! -f /etc/dovecot/conf.d/auth-sql.conf.ext.orig ]; then
  cp /etc/dovecot/conf.d/auth-sql.conf.ext /etc/dovecot/conf.d/auth-sql.conf.ext.orig
fi
if [ ! -f /etc/dovecot/dovecot-sql.conf.ext.orig ]; then
  cp /etc/dovecot/dovecot-sql.conf.ext /etc/dovecot/dovecot-sql.conf.ext.orig
fi

sed -i 's/^mail_location =.*/mail_location = maildir:\/var\/vmail\/vhosts\/%d\/%n\//g' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/^#mail_uid =.*/mail_uid = vmail/g' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/^#mail_gid =.*/mail_gid = vmail/g' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/^#mail_privileged_group =.*/#mail_privileged_group = vmail/g' /etc/dovecot/conf.d/10-mail.conf

cat <<_EOF_ > /etc/dovecot/conf.d/auth-sql.conf.ext
passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}
userdb {
  driver = static
  args = uid=vmail gid=vmail home=/var/vmail/vhosts/%d/%n
}
_EOF_

cat <<_EOF_ > /etc/dovecot/dovecot-sql.conf.ext
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

chown -R vmail:dovecot /etc/dovecot
chmod -R o-rwx /etc/dovecot 

# ==========================================
#  Merge Postfix and Dovecot
# ==========================================

if [[ ! $(grep -F dovecot /etc/postfix/master.cf) ]]; then 
  echo "dovecot   unix  -       n       n       -       -       pipe" >> /etc/postfix/master.cf
  echo "   flags=DRhu user=vmail:vmail argv=/usr/lib/dovecot/dovecot-lda -f ${sender} -d ${recipient}" >> /etc/postfix/master.cf
fi

service dovecot restart
service postfix restart
