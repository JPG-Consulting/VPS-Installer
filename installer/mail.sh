#!/bin/bash
# References: https://wiki.debian.org/Postfix#Installing_and_Configuring_Postfix_on_Debian

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