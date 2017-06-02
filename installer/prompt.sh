#!/bin/bash
# here we ask for the questions needed to proceed with the system installation

while true; then

  if prompt_yn "Does it look ok?"; then
    break
  fi
done
