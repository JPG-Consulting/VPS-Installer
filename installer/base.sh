#!/bin/bash

function base_set_timezone {
  local __timezone='Europe/Madrid'
  if [ -f /etc/timezone ]; then
    __timezone=$(cat /ect/timezone)
  fi
  
  while true; do
    read -p "Timezone [$__timezone]: " __timezone
    if [ -z "$__timezone" ]; then
      if [ -f /etc/timezone ]; then
        __timezone=$(cat /ect/timezone)
      else
        __timezone='Europe/Madrid'
      fi
    fi
    if [ -f "/usr/share/zoneinfo/$__timezone"]; then
      break;
    else
      echo "Error: Bad timezone";
    fi
  done
  
  cp /usr/share/zoneinfo/$__timezone /etc/localtime
  if [ -f /etc/timezone ]; then
    echo $__timezone > /ect/timezone
  fi
}
