#!/bin/bash


# ===========================================
#  Postfix SMTP
# ===========================================

if ! is_package_installed postfix; then
  # TODO: change this with the hostname
  debconf-set-selections <<< "postfix postfix/mailname string '$HOSTNAME'"
  debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

  apt-get --yes install postfix
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install postfix."
    exit 1
  fi
fi

if ! is_package_installed postfix-mysql; then
  apt-get --yes install postfix-mysql
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install postfix-mysql."
    exit 1
  fi
fi

# ===========================================
#  Dovecot IMAP
# ===========================================

if ! is_package_installed dovecot-imapd; then
  apt-get --yes install dovecot-imapd
  if [ $? -ne 0 ]; then
    echo "Error: Failed to install dovecot-imapd."
    exit 1
  fi
fi
