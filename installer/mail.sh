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
postconf -e "myorigin = $HOSTNAME"
# Add your hostname (computer name). (Use command "hostname" at the command-line to display your hostname if not sure.)
postconf -e "myhostname=$HOSTNAME"
# Now add the domain names that your system will handle.
postconf -e "relay_domains = $HOSTNAME"


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
