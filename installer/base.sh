#!/bin/bash

while true; do
  read -p "Timezone [Europe/Madrid]: " TIMEZONE
  if [ -z "$TIMEZONE" ]; then
    TIMEZONE="Europe/Madrid"
  fi
  if [ -f "/usr/share/zoneinfo/$TIMEZONE"]; then
    break;
  else
    echo "Error: Bad timezone";
  fi
done
  
cp /usr/share/zoneinfo/$TIMEZONE /etc/localtime
echo $TIMEZONE > /ect/timezone
