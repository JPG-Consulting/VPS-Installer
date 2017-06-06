#!/bin/bash

function base_set_timezone {
  local __timezone='Europe/Madrid'
  if [ -f /etc/timezone ]; then
    __timezone=$(cat /etc/timezone)
  fi
  
  while true; do
    read -p "Timezone [$__timezone]: " __timezone
    if [ -z "$__timezone" ]; then
      if [ -f /etc/timezone ]; then
        __timezone=$(cat /etc/timezone)
      else
        __timezone='Europe/Madrid'
      fi
    fi
    if [ -f "/usr/share/zoneinfo/$__timezone" ]; then
      break;
    else
      echo "Error: Bad timezone";
    fi
  done
  
  cp /usr/share/zoneinfo/$__timezone /etc/localtime
  echo $__timezone > /etc/timezone
  chown root:root /etc/timezone
  chmod 0644 /etc/timezone
}
